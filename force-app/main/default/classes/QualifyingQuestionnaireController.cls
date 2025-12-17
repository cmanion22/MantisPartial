public with sharing class QualifyingQuestionnaireController {

    // -----------------------------
    // 1) Base: questions by solution type
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static List<Qualifying_Question__c> getQuestionsBySolutionType(String solutionType) {
        System.debug('[Apex] getQuestionsBySolutionType called with solutionType: ' + solutionType);

        if (String.isBlank(solutionType)) {
            System.debug('[Apex] getQuestionsBySolutionType: solutionType is blank -> return empty');
            return new List<Qualifying_Question__c>();
        }

        List<Qualifying_Question__c> questions = [
            SELECT Id, Name, Question_Name__c, Display_Order__c, Solution_Type__c,
                   IsActive__c, Picklist_Values__c, Field_Type__c, Sub_Type__c, Required_or_Optional__c
            FROM Qualifying_Question__c
            WHERE IsActive__c = TRUE
              AND Solution_Type__c INCLUDES (:solutionType)
            ORDER BY Display_Order__c ASC, Question_Name__c ASC
        ];

        System.debug('[Apex] Retrieved questions count: ' + questions.size());
        return questions;
    }

    // -----------------------------
    // 2) NEW: questions by solution type + Mechanical Sub-Type
    //    Always include "Mechanical General" first, then the selected subtype
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static List<Qualifying_Question__c> getQuestionsBySolutionTypeWithSubtype(
        String solutionType,
        String mechanicalSubtype
    ) {
        System.debug('[Apex][Subtype] called. solutionType=' + solutionType + ' | mechanicalSubtype=' + mechanicalSubtype);

        if (String.isBlank(solutionType)) {
            System.debug('[Apex][Subtype] solutionType is blank -> return empty');
            return new List<Qualifying_Question__c>();
        }

        String solLower = solutionType != null ? solutionType.toLowerCase() : '';
        Boolean isMechanical = (solLower == 'hvac/mechanical') || (solLower == 'mechanical') || solLower.contains('mechanical');

        if (!isMechanical) {
            System.debug('[Apex][Subtype] Not mechanical -> delegate to base method.');
            return getQuestionsBySolutionType(solutionType);
        }

        // 2a) Always pull "Mechanical General" first
        List<Qualifying_Question__c> general = [
            SELECT Id, Name, Question_Name__c, Display_Order__c, Solution_Type__c,
                   IsActive__c, Picklist_Values__c, Field_Type__c, Sub_Type__c, Required_or_Optional__c
            FROM Qualifying_Question__c
            WHERE IsActive__c = TRUE
              AND Solution_Type__c INCLUDES ('HVAC/Mechanical')
              AND Sub_Type__c = 'Mechanical General'
            ORDER BY Display_Order__c ASC, Question_Name__c ASC
        ];
        System.debug('[Apex][Subtype] Mechanical General count=' + general.size());

        // 2b) If a specific subtype is provided (and not the same as Mechanical General), pull those too
        List<Qualifying_Question__c> specific = new List<Qualifying_Question__c>();
        if (!String.isBlank(mechanicalSubtype) && mechanicalSubtype != 'Mechanical General') {
            specific = [
                SELECT Id, Name, Question_Name__c, Display_Order__c, Solution_Type__c,
                       IsActive__c, Picklist_Values__c, Field_Type__c, Sub_Type__c, Required_or_Optional__c
                FROM Qualifying_Question__c
                WHERE IsActive__c = TRUE
                  AND Solution_Type__c = :solutionType
                  AND Sub_Type__c = :mechanicalSubtype
                ORDER BY Display_Order__c ASC, Question_Name__c ASC
            ];
            System.debug('[Apex][Subtype] Specific subtype "' + mechanicalSubtype + '" count=' + specific.size());
        }

        // 2c) Merge: general first, then specific
        List<Qualifying_Question__c> out = new List<Qualifying_Question__c>();
        out.addAll(general);
        out.addAll(specific);
        System.debug('[Apex][Subtype] Final merged count=' + out.size());
        return out;
    }

    // -----------------------------
    // 3) Create form + responses; returns the new Form Id
    //    responsesJson = [
    //      {"qualifyingQuestionId":"a01...", "responseText":"foo"},
    //      ...
    //    ]
    // -----------------------------
    @AuraEnabled
    public static Id createFormWithResponses(
        Id projectId,
        String solutionType,
        String opportunityId,
        String responsesJson
    ) {
        System.debug('[Apex] createFormWithResponses called');
        System.debug('[Apex] projectId=' + projectId + ', solutionType=' + solutionType + ', opportunityId=' + opportunityId);
        System.debug('[Apex] responsesJson=' + responsesJson);

        if (projectId == null) {
            System.debug('[Apex] Abort: projectId is null');
            return null;
        }

        try {
            // Create the parent form
            Qualifying_Questionnaire_Form__c form = new Qualifying_Questionnaire_Form__c(
                Project__c        = projectId,
                Opportunity__c    = opportunityId
            );
            insert form;
            System.debug('[Apex] Inserted Form Id: ' + form.Id);

            // Allow empty responsesJson (we still want the form created)
            if (!String.isBlank(responsesJson)) {
                List<Object> rawList = (List<Object>) JSON.deserializeUntyped(responsesJson);
                Integer parsed = (rawList == null ? 0 : rawList.size());
                System.debug('[Apex] Parsed responses count: ' + parsed);

                if (parsed > 0) {
                    List<Qualifying_Question_Response__c> toInsert = new List<Qualifying_Question_Response__c>();
                    for (Object o : rawList) {
                        Map<String, Object> row = (Map<String, Object>) o;
                        String qIdStr   = (String) row.get('qualifyingQuestionId');
                        String respText = (String) row.get('responseText');

                        System.debug('[Apex] Row -> qualifyingQuestionId=' + qIdStr + ', responseText=' + respText);

                        if (!String.isBlank(qIdStr)) {
                            toInsert.add(new Qualifying_Question_Response__c(
                                Qualifying_Questionnaire_Form__c = form.Id,
                                Qualifying_Question__c           = Id.valueOf(qIdStr),
                                Response__c                      = respText
                            ));
                        } else {
                            System.debug('[Apex] Skipping row due to missing qualifyingQuestionId: ' + row);
                        }
                    }

                    if (!toInsert.isEmpty()) {
                        insert toInsert;
                        System.debug('[Apex] Inserted response records: ' + toInsert.size());
                    } else {
                        System.debug('[Apex] No valid response rows to insert.');
                    }
                } else {
                    System.debug('[Apex] No responses parsed.');
                }
            } else {
                System.debug('[Apex] responsesJson blank; created form with no responses.');
            }

            return form.Id;

        } catch (Exception e) {
            System.debug('[Apex] ERROR in createFormWithResponses: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            return null;
        }
    }

    // -----------------------------
    // 4) DTO for the read-side LWC (viewer)
    // -----------------------------
    public class QuestionResponseDTO {
        @AuraEnabled public Id     questionId;
        @AuraEnabled public String questionName;
        @AuraEnabled public String fieldType;
        @AuraEnabled public String picklistValues; // semicolon-delimited
        @AuraEnabled public Decimal displayOrder;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String requiredOrOptional;
        @AuraEnabled public Id     responseId;     // may be null if not created yet
        @AuraEnabled public String responseText;
    }

    // -----------------------------
    // 5) Get rows (question + response) for a given form
    // -----------------------------
    @AuraEnabled(cacheable=true)
    public static List<QuestionResponseDTO> getResponsesForForm(Id formId) {
        System.debug('[Apex] getResponsesForForm formId=' + formId);
        if (formId == null) return new List<QuestionResponseDTO>();

        Qualifying_Questionnaire_Form__c form = [
            SELECT Id, Solution_Type__c
            FROM Qualifying_Questionnaire_Form__c
            WHERE Id = :formId
            LIMIT 1
        ];

        List<Qualifying_Question__c> questions = [
            SELECT Id, Question_Name__c, Field_Type__c, Picklist_Values__c, Display_Order__c, Required_or_Optional__c
            FROM Qualifying_Question__c
            WHERE IsActive__c = TRUE
              AND Solution_Type__c INCLUDES (:form.Solution_Type__c)
            ORDER BY Display_Order__c ASC, Question_Name__c ASC
        ];

        Map<Id, Qualifying_Question_Response__c> respByQuestion = new Map<Id, Qualifying_Question_Response__c>();
        for (Qualifying_Question_Response__c r : [
            SELECT Id, Qualifying_Question__c, Response__c, Qualifying_Questionnaire_Form__c
            FROM Qualifying_Question_Response__c
            WHERE Qualifying_Questionnaire_Form__c = :formId
        ]) {
            respByQuestion.put(r.Qualifying_Question__c, r);
        }

        List<QuestionResponseDTO> out = new List<QuestionResponseDTO>();
        for (Qualifying_Question__c q : questions) {
            QuestionResponseDTO dto = new QuestionResponseDTO();
            dto.questionId      = q.Id;
            dto.questionName    = q.Question_Name__c;
            dto.fieldType       = q.Field_Type__c;
            dto.picklistValues  = q.Picklist_Values__c;
            dto.displayOrder    = q.Display_Order__c;
            dto.isRequired = (q.Required_or_Optional__c == 'Required');
            dto.requiredOrOptional = q.Required_or_Optional__c;

            if (respByQuestion.containsKey(q.Id)) {
                Qualifying_Question_Response__c rr = respByQuestion.get(q.Id);
                dto.responseId   = rr.Id;
                dto.responseText = rr.Response__c;
            } else {
                dto.responseId   = null;
                dto.responseText = null;
            }
            out.add(dto);
        }
        System.debug('[Apex] getResponsesForForm returned ' + out.size() + ' rows');
        return out;
    }

    // -----------------------------
    // 6) Upsert responses for a form (viewer edit/save)
    // -----------------------------
    @AuraEnabled
    public static Boolean saveResponses(Id formId, String responsesJson) {
        System.debug('[Apex] saveResponses formId=' + formId);
        System.debug('[Apex] responsesJson=' + responsesJson);
        if (formId == null || String.isBlank(responsesJson)) return false;

        List<Object> raw = (List<Object>) JSON.deserializeUntyped(responsesJson);
        if (raw == null || raw.isEmpty()) {
            System.debug('[Apex] No rows to save');
            return true;
        }

        Map<Id, Qualifying_Question_Response__c> byQuestion = new Map<Id, Qualifying_Question_Response__c>();
        for (Qualifying_Question_Response__c e : [
            SELECT Id, Qualifying_Question__c
            FROM Qualifying_Question_Response__c
            WHERE Qualifying_Questionnaire_Form__c = :formId
        ]) {
            byQuestion.put(e.Qualifying_Question__c, e);
        }

        List<Qualifying_Question_Response__c> toUpsert = new List<Qualifying_Question_Response__c>();
        for (Object rowObj : raw) {
            Map<String, Object> row = (Map<String, Object>) rowObj;
            String qIdStr   = (String) row.get('qualifyingQuestionId');
            String respText = (String) row.get('responseText');

            if (String.isBlank(qIdStr)) continue;

            Id qId = Id.valueOf(qIdStr);

            if (byQuestion.containsKey(qId)) {
                Qualifying_Question_Response__c ex = byQuestion.get(qId);
                ex.Response__c = respText;
                toUpsert.add(ex);
            } else {
                toUpsert.add(new Qualifying_Question_Response__c(
                    Qualifying_Questionnaire_Form__c = formId,
                    Qualifying_Question__c           = qId,
                    Response__c                      = respText
                ));
            }
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert;
            System.debug('[Apex] Upserted responses: ' + toUpsert.size());
        } else {
            System.debug('[Apex] Nothing to upsert.');
        }
        return true;
    }
}
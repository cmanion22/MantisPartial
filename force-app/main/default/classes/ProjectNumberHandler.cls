public with sharing class ProjectNumberHandler {

    public static void assignNumbersForOpportunity(Opportunity opp, Id ParentOppId) {
        try {
            System.debug('Entering ProjectNumberHandler.assignNumbersForOpportunity()');
            System.debug('ProjectNumberHandler.assignNumbersForOpportunity() Opp: ' + opp);
            System.debug('ProjectNumberHandler.assignNumbersForOpportunity() ParentOppId: ' + ParentOppId);

            // Get and increment the sequence and ensure it is unique per closed opp record
            AutoNumber_Sequence__c seq = [
                SELECT Id, Current_AutoNumber__c 
                FROM AutoNumber_Sequence__c 
                WHERE Name = 'Project' 
                LIMIT 1 
                FOR UPDATE
            ];

            Integer currentNumber = Integer.valueOf(seq.Current_AutoNumber__c) + 1;
            seq.Current_AutoNumber__c = String.valueOf(currentNumber);
            update seq;

            // Assign the base number directly to Opportunity
            String baseNumber = String.valueOf(currentNumber);
            opp.Project_Number__c = baseNumber;

            //Query all related projects
            list<Project__c> relatedCOs = new list<Project__c>();
            List<Project__c> allRelatedProjects = [
                SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c
                FROM Project__c 
                WHERE Opportunity__c = :opp.Id
            ];

            for(Project__c p : allRelatedProjects){
                if(p.Type__c == 'Change Order'){
                    relatedCOs.add(p);
                }
            }

            // Query related standardprojects
            List<Project__c> standardProjects = [
                SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c
                FROM Project__c 
                WHERE Type__c = 'Standard Project'
                AND Opportunity__c = :opp.Id
            ];

            // Iteration counters for project numbers
            Integer standardCount = 0;
            Integer ptCount = 0;
            Integer expCount = 0;
            Integer changeOrderCount = 0;
            Integer standardParentPTCount = 0;
            Integer standardParentEXPCount = 0;

            //Build Lists
            Set<Id> standardProjectIds = new Set<Id>();
            list<Project__c> childProjectsToUpdate = new list<Project__c>();

            // Loop through all related projects
            for(Project__c proj : standardProjects){
                standardCount++;
                // Assign standard project number
                String suffix = (standardCount < 50 ? '-0' : '-') + standardCount;
                proj.Project_Number__c = baseNumber + suffix;
                standardProjectIds.add(proj.Id);
            }

            // Single bulk update for all projects
            if(!standardProjects.isEmpty()) {
                update standardProjects;
            }

            //query child projects
            List<Project__c> childProjects = [
                SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c
                FROM Project__c 
                WHERE Parent_Project__c IN :standardProjectIds
            ];

            for(Project__c childProj : childProjects){
                if(childProj.Type__c == 'PT'){
                    if(ptCount == 0){
                        childProj.Project_Number__c = childProj.Parent_Project__r.Project_Number__c + '-' + childProj.Type__c;
                        ptCount++;
                        childProjectsToUpdate.add(childProj);
                    } else {
                        childProj.Project_Number__c = childProj.Parent_Project__r.Project_Number__c + '-' + childProj.Type__c + ptCount;
                        ptCount++;
                        childProjectsToUpdate.add(childProj);
                    }
                }
                if(childProj.Type__c == 'EXP'){
                    if(expCount == 0){
                        childProj.Project_Number__c = childProj.Parent_Project__r.Project_Number__c + '-' + childProj.Type__c;
                        expCount++;
                        childProjectsToUpdate.add(childProj);
                    } else {
                        childProj.Project_Number__c = childProj.Parent_Project__r.Project_Number__c + '-' + childProj.Type__c + expCount;
                        expCount++;
                        childProjectsToUpdate.add(childProj);
                    }
                }
            }

            if (!childProjectsToUpdate.isEmpty()) {
                update childProjectsToUpdate;
            }

            if(!relatedCOs.isEmpty()){
                list<Project__c> changeOrdersToUpdate = new List<Project__c>();
                Set<Id> coProjectIds = new Set<Id>();

                System.debug('Parent Opportunity Id: ' + opp.Id);
                System.debug('Querying Parent Project to the CO');
                //Need to add if here to change the parentStandardCOProject if the COs parent project is a PT
                // First get the parent project of the current CO
                
                Project__c parentStandardCOProject;

                Project__c coParentProject = [
                    SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Type__c, Parent_Project__r.Parent_Project__c
                    FROM Project__c
                    WHERE Opportunity__c = :opp.Id 
                    LIMIT 1
                ];
                System.debug('CO Project Id: ' + coParentProject);
                System.debug('CO Parent Project Type: ' + coParentProject.Type__c);

                
                if (coParentProject.Parent_Project__r.Type__c == 'PT') {
                    // Parent of PT (i.e., grandparent of CO)
                    parentStandardCOProject = [
                        SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c, Project_Number__c, Opportunity__c
                        FROM Project__c
                        WHERE Id = :coParentProject.Parent_Project__c
                        LIMIT 1
                    ];
                    System.debug('Parent PT Project: ' + parentStandardCOProject);
                } else {
                    // Parent is a Standard Project directly
                    parentStandardCOProject = [
                        SELECT Id, Type__c, Project_Number__c, Parent_Project__r.Type__c
                        FROM Project__c
                        WHERE Id = :coParentProject.Parent_Project__c
                        LIMIT 1
                    ];
                        System.debug('Parent Standard Project: ' + parentStandardCOProject);
                }

                List<Project__c> parentStandardPTEXPProjects = [
                    SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c, Project_Number__c, Opportunity__c
                    FROM Project__c
                    WHERE (Type__c = 'PT' OR Type__c = 'EXP')
                    AND Parent_Project__c = :parentStandardCOProject.Id
                ];

                System.debug('Parent parentStandardPTEXPProjects Project: ' + parentStandardPTEXPProjects);

                if (!parentStandardPTEXPProjects.isEmpty()) {
                    for(Project__c standardPTorEXP : parentStandardPTEXPProjects){
                        if(standardPTorEXP.Type__c == 'PT'){
                            standardParentPTCount++;
                        }
                        if(standardPTorEXP.Type__c == 'EXP'){
                            standardParentEXPCount++;
                        }
                    }
                }

                if (parentStandardCOProject != null) {
                    System.debug('Change Order Parent Project: ' + parentStandardCOProject.Id);
                    List<Project__c> changeOrderProjects = [
                        SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c, Project_Number__c, Parent_Project__r.Type__c
                        FROM Project__c
                        WHERE Type__c = 'Change Order'
                        AND Parent_Project__c = :parentStandardCOProject.Id
                    ];
                    System.debug('changeOrderProjects size: ' + changeOrderProjects.size());

                    if (!changeOrderProjects.isEmpty()) {
                        for (Project__c coProj : changeOrderProjects) {
                            changeOrderCount++;
                            //Logic needed here based on parent projec type PT or Standard
                            if(coProj.Parent_Project__r.Type__c == 'PT'){
                            String calculatedNumber = parentStandardCOProject.Parent_Project__r.Project_Number__c + '-CO' + changeOrderCount;
                            coProj.Project_Number__c = calculatedNumber;
                            System.debug('coProj Project Number: ' + calculatedNumber);

                            }else{
                            String calculatedNumber = parentStandardCOProject.Project_Number__c + '-CO' + changeOrderCount;
                            coProj.Project_Number__c = calculatedNumber;

                            }
                            //String calculatedNumber = parentStandardCOProject.Project_Number__c + '-CO' + changeOrderCount;
                            //coProj.Project_Number__c = calculatedNumber;
                            changeOrdersToUpdate.add(coProj);
                            coProjectIds.add(coProj.Id);
                        }
                    System.debug('Current Project Number>>:' +changeOrderCount);
                    }
                } else {
                    System.debug('Parent Project Not Found');
                }

                if (!changeOrdersToUpdate.isEmpty()) {
                    System.debug('>>> Updating ' + changeOrdersToUpdate.size() + ' Change Order Projects...');
                    for (Project__c p : changeOrdersToUpdate) {
                        System.debug('>>> Final Update: CO Id = ' + p.Id + ', Number = ' + p.Project_Number__c);
                    }
                    update changeOrdersToUpdate;
                }

                list<Project__c> coChildProjectsUpdate = new list<Project__c>();
                list<Project__c> coChildProjects = [
                    SELECT Id, Type__c, Parent_Project__c, Parent_Project__r.Project_Number__c, Project_Number__c, Parent_Project__r.Type__c
                    FROM Project__c
                    WHERE Parent_Project__c IN :coProjectIds
                ];

                Integer coPTCount = 0;
                Integer coEXPCount = 0;
                Integer coPTandStandardPTCount = 0;
                Integer coEXPandStandardEXPCount = 0;

                for(Project__c coChildProj : coChildProjects){
                    if(coChildProj.Type__c == 'PT'){
                        if(coPTCount == 0 && standardParentPTCount == 0){
                            coChildProj.Project_Number__c = parentStandardCOProject.Project_Number__c + '-' + coChildProj.Type__c;
                            coPTCount++;
                            coChildProjectsUpdate.add(coChildProj);
                        } else {
                            coPTandStandardPTCount = coPTCount + standardParentPTCount;
                            coChildProj.Project_Number__c = parentStandardCOProject.Project_Number__c + '-' + coChildProj.Type__c + coPTandStandardPTCount;
                            coPTCount++;
                            coChildProjectsUpdate.add(coChildProj);
                        }
                    }
                    if(coChildProj.Type__c == 'EXP'){
                        if(coEXPCount == 0 && standardParentPTCount == 0){
                            coChildProj.Project_Number__c = parentStandardCOProject.Project_Number__c + '-' + coChildProj.Type__c;
                            coEXPCount++;
                            coChildProjectsUpdate.add(coChildProj);
                        } else {
                            coEXPandStandardEXPCount = coEXPCount + coEXPandStandardEXPCount;
                            coChildProj.Project_Number__c = parentStandardCOProject.Project_Number__c + '-' + coChildProj.Type__c + coEXPandStandardEXPCount;
                            coEXPCount++;
                            coChildProjectsUpdate.add(coChildProj);
                        }
                    }
                }

                update coChildProjectsUpdate;
            }

        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            Data_Log__c log = new Data_Log__c(
                Related_Record_Id__c = opp.Id,
                Log_Origin__c = 'ProjectNumberHandler',
                Description__c = e.getMessage()
            );
            insert log;
        }
    }
}
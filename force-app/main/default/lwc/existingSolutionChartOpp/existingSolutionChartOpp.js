import { LightningElement, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJs from '@salesforce/resourceUrl/chartJS'; // Ensure this matches your static resource name
import getOpportunities from '@salesforce/apex/OpportunityExistingSolutionController.getOpportunities';

export default class ExistingSolutionChartOpp extends LightningElement {
    @api recordId;  // Automatically populated with the record ID of the Opportunity
    chart;
    chartJsInitialized = false;
    oppData = [];
    solutionTypeName = ''; // Holds the solution type name
    recordCount = 0; // Holds the count of records returned
    maxCloseDateYear = 0; // Holds the maximum close date year from the data

    // Wire method to get related Opportunities
    @wire(getOpportunities, { opportunityId: '$recordId' })
    wiredOpportunities({ error, data }) {
        console.log('Record ID:', this.recordId);  // Debugging the recordId
        if (data) {
            this.oppData = data;
            this.recordCount = this.oppData.length;
            this.solutionTypeName = `${this.getSolutionTypeName()} (${this.recordCount})`;

            // Calculate the maximum close date year from the data
            this.maxCloseDateYear = this.oppData.reduce((max, opp) => {
                const closeDateYear = opp?.closeDateYear ? Math.floor(opp.closeDateYear) : null;
                return closeDateYear && closeDateYear > max ? closeDateYear : max;
            }, 0);

            console.log('Solution Type:', this.solutionTypeName);
            console.log('Record Count:', this.recordCount);
            console.log('Opportunity data:', this.oppData);  // Debugging the data received
            console.log('Max Close Date Year:', this.maxCloseDateYear); // Debugging the max year

           
        } else if (error) {
            console.error('Error fetching opportunities:', error);
        }
    }

    // Extract the solution type name from the data
    getSolutionTypeName() {
        if (this.oppData.length > 0) {
            return this.oppData[0].typeOfService || 'Unknown'; // Assuming all records have the same Type_of_Service__c
        }
        return 'Unknown';
    }

    // Load Chart.js script only once
    renderedCallback() {
        if (this.chartJsInitialized) {
            return;
        }
    
        // Set the flag to true to prevent further reinitialization
        this.chartJsInitialized = true;
    
        loadScript(this, ChartJs)
            .then(() => {
                if (window.Chart && typeof window.Chart === 'function') {
                    console.log('Chart.js successfully loaded');
    
                    // Wait for a brief delay to ensure everything is ready
                    return this.wait(500); // wait for 500 ms, or any time that you feel necessary
                } else {
                    throw new Error('Chart.js did not load as expected. window.Chart is not a constructor.');
                }
            })
            .then(() => {
                // Only initialize the chart once Chart.js is loaded and everything is ready
                this.initializeChart();
            })
            .catch(error => {
                console.error('Error loading Chart.js:', error);
            });
    }
    
    // Wait function (returns a promise that resolves after a delay)
    wait(ms) {
        console.log('Wait function called to delay initialization of chart.');
        console.log('Waiting for ' + ms + ' milliseconds');
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    

    // Initialize Chart.js and render the horizontal bar chart
    initializeChart() {
        if (this.chart) {
            this.chart.destroy(); // Destroy the old chart if it exists
        }

        const canvas = this.template.querySelector('canvas');
        if (!canvas) {
            console.error('Canvas element not found');
            return;
        }

        canvas.width = 150; // Adjust chart width
        canvas.height = 75; // Adjust chart height

        const ctx = canvas.getContext('2d');

        const yearLabels = []; // Unique year labels for the x-axis
        const yearData = {}; // Group data by year

        // Group data by year
        this.oppData.forEach((opp) => {
            const closeDateYear = opp.closeDateYear ? Math.floor(opp.closeDateYear) : 'Unknown';
            if (!yearData[closeDateYear]) {
                yearData[closeDateYear] = 0;
                yearLabels.push(closeDateYear); // Add year to x-axis labels
            }
            yearData[closeDateYear] += 1; // Increment count for that year
        });

        // Add a dummy entry to ensure the chart starts at 0
        if (this.maxCloseDateYear) {
            const nextYear = this.maxCloseDateYear + 1;
            if (!yearData[nextYear]) {
                yearData[nextYear] = 0; // Include next year in data
                yearLabels.push(nextYear); // Add next year to x-axis labels
            }
        }

        const chartData = {
            labels: yearLabels,
            datasets: [
                {
                    label: this.solutionTypeName, // Use the solution type as the dataset label
                    data: yearLabels.map((year) => yearData[year]), // Data for each year
                    backgroundColor: 'rgba(0, 77, 153, 0.8)',
                    borderColor: 'rgba(0, 51, 102, 1)',
                    borderWidth: 2,
                },
            ],
        };

        this.chart = new window.Chart(ctx, {
            type: 'bar',
            data: chartData,
            options: {
                indexAxis: 'x', // Horizontal bar chart
                responsive: true,
                scales: {
                    x: {
                        ticks: {
                            maxRotation: 0, // Prevent rotation
                            minRotation: 0, // Prevent rotation
                            autoSkip: false, // Ensure all labels show
                            stepSize: 1,
                        },
                        title: {
                            display: true,
                            text: 'Year', // Label for the x-axis
                        },
                    },
                    y: {
                        beginAtZero: true,
                        suggestedmin: 0, // Always start at 0
                        suggestedmax: 15,
                        ticks: {
                            beginAtZero: true,
                        },
                        title: {
                            display: true,
                            text: 'Record Count',
                        },
                    },
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top',
                        labels: {
                            font: {
                                size: 14,
                            },
                        },
                    },
                    tooltip: {
                        callbacks: {
                            label: function (tooltipItem) {
                                return `Year: ${tooltipItem.label}, Count: ${tooltipItem.raw}`;
                            },
                        },
                    },
                },
                layout: {
                    padding: {
                        top: 3,
                        bottom: 3,
                        left: 3,
                        right: 3,
                    },
                },
            },
        });
    }
}
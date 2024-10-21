import { LightningElement, track } from 'lwc';
import punchInAttendance from '@salesforce/apex/AttendanceKirtiController.punchInAttendance';
import punchOutAttendance from '@salesforce/apex/AttendanceKirtiController.punchOutAttendance';
import checkOrCreateMonthlyAttendance from '@salesforce/apex/AttendanceKirtiController.checkOrCreateMonthlyAttendance';
import checkAttendanceForUser from '@salesforce/apex/AttendanceKirtiController.checkAttendanceForUser';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DateAndTime from '@salesforce/schema/OperatingHoursHoliday.DateAndTime';

export default class MyAttendanceManagement extends LightningElement {
    @track punchInDisabled = false;
    @track punchOutDisabled = true;
    @track wfhDisabled = false;
    @track currentTime;
    @track currentDate;
    @track punchInTime;
    @track punchOutTime;

    connectedCallback() {
        
        this.startTimer(); // Start the timer to update current time
        this.checkForAttendance();
    }

    checkForAttendance(){
        console.log('OUTPUT :under check ');
        checkAttendanceForUser()
        .then((result) => {
                        console.log(result);

            if(result){
                console.log(result);
                if(!result.Punch_In__c ){
                    console.log('!result.Punch_In__c');
                    
                    this.punchInDisabled = true;
                    this.punchOutDisabled = false;
                    this.wfhDisabled = true;
                }

               else if(result.Punch_In__c && !result.Punch_Out__c){
                console.log('result.Punch_In__c && !result.Punch_Out__c');

                    this.punchInDisabled = true;
                    this.punchOutDisabled = false;
                    this.wfhDisabled = true;
                }
                else if(result.Punch_Out__c || result.Work_From_Home__c){
                    console.log('result.Punch_Out__c || result.Work_From_Home__c');

                    this.punchInDisabled = true;
                    this.wfhDisabled = true;
                    this.punchOutDisabled = true;

                }
                else{
                    console.log('else');

                    this.punchInDisabled = true;
                    this.punchOutDisabled = false;
                    this.wfhDisabled = true;
                }

              
            }
        })
        .catch(() => {
            this.showToast('Error', 'Error ', 'error');
        });
    }

    startTimer() {
        setInterval(() => {
            this.currentTime = this.getCurrentTime(); // Update current time
            this.currentDate = this.getCurrentDate(); // Update current date
        }, 1000);
    }

    // Get current time in hh:mm:ss AM/PM format
    getCurrentTime() {
        const now = new Date();
        const hours = now.getHours();
        const minutes = this.padZero(now.getMinutes());
        const seconds = this.padZero(now.getSeconds());
        const ampm = hours >= 12 ? 'PM' : 'AM';

        return `${this.padZero(hours % 12 || 12)}:${minutes}:${seconds} ${ampm}`;
    }

    // Get current date in dd/mm/yyyy format
    getCurrentDate() {
        const now = new Date();
        return `${this.padZero(now.getDate())}/${this.padZero(now.getMonth() + 1)}/${now.getFullYear()}`;
    }

    padZero(value) {
        return value < 10 ? '0' + value : value; // Add leading zero if necessary
    }

    // checkAttendanceState() {
    //     checkOrCreateMonthlyAttendance()
    //         .then((result) => {
    //             const today = new Date().toISOString().slice(0, 10); // Get current date
    //             if (result) {
    //                 // Update button states based on attendance records
    //                 this.punchInDisabled = result.Punch_In__c && result.Punch_In__c.slice(0, 10) === today;
    //                 this.punchOutDisabled = !result.Punch_In__c || result.Punch_Out__c;
    //                 this.wfhDisabled = result.Punch_In__c || result.Punch_Out__c;
    //             }
    //         })
    //         .catch(() => {
    //             this.showToast('Error', 'Error checking attendance state', 'error');
    //         });
    // }

    handlePunchIn() {
        console.log("In handle Punch In")
        this.punchInTime = new Date().toLocaleTimeString();
        punchInAttendance({'isWorkFromHome':false})
            .then((result) => {
                //this.punchInTime = result.Punch_In__c;
                this.punchInDisabled = true;
                this.punchOutDisabled = false;
                this.wfhDisabled = true;
                this.showToast('Success', 'Punched in successfully!', 'success');
            })
            .catch(() => {
                this.showToast('Error', 'Error punching in', 'error');
            });
    }

    handlePunchOut() {
        // console.log("Punch out time:"+new Date().toLocaleTimeString());
        this.punchOutTime =new Date().toLocaleTimeString();
        console.log('punch out '+this.punchOutTime);
        
        punchOutAttendance()
            .then((result) => {
                console.log('result'+result);
                
         //       this.punchOutTime = result.Punch_Out__c;
         //       this.calculateTotalHours();

             
         const punchOutTime = new Date(result.Punch_Out__c); // Parse as Date object
         console.log('time for ounch out '+this.punchOutTime);
         
         //  this.punchOutTime = this.getFormattedTime(punchOutTime); // Format the time for UI
            //   this.calculateTotalHours();

                this.punchInDisabled = true;
                this.punchOutDisabled = true;
                this.wfhDisabled = true;
                this.showToast('Success', 'Punched out successfully!', 'success');
            })
            .catch((error) => {
                console.log(error);
                
                this.showToast('Error', 'Error punching out', 'error');
            });
            console.log(this.punchOutTime);
            
    }

    handleWFH() {
        this.punchInDisabled = true;
        this.punchOutDisabled = true;
        this.wfhDisabled = true;
        console.log('under WFH');
        
        punchInAttendance({'isWorkFromHome':true}) // Using punchInAttendance for WFH scenario
            .then((result) => {
                console.log(result);
                
                this.punchInTime = result.Punch_In__c;
              
                this.showToast('Success', 'Work From Home punched in successfully!', 'success');
            })
            .catch((error) => {
                console.log(error);
                this.showToast('Error', 'Error in Work From Home punch in', 'error');
            });
    }
 
 
    


calculateTotalHours() {
    if (this.punchInTime && this.punchOutTime) {
    

        const punchInDate = new Date(this.punchInTime); // Parse the time into Date object
        const punchOutDate = new Date(this.punchOutTime); // Parse punch-out as Date object

        // Calculate the difference in milliseconds between punch-in and punch-out
        const diffMs = punchOutDate - punchInDate; // Calculate the difference in milliseconds
        
        // Convert milliseconds to hours, minutes, and seconds
        const totalSeconds = Math.floor(diffMs / 1000);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;

        // Format total hours as HH:MM:SS
        this.totalHours = `${this.padZero(hours)}:${this.padZero(minutes)}:${this.padZero(seconds)}`;
    } else {
        this.totalHours = '00:00:00'; // Reset if not both times are set
    }
}

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    checkButtonState() {
        const today = new Date().toISOString().slice(0, 10);
        const punchInState = localStorage.getItem('punchInState');
        const punchOutState = localStorage.getItem('punchOutState');

        if (punchInState === today) {
            this.punchInDisabled = true;  // Punch In already recorded today
            this.punchOutDisabled = false; // Allow Punch Out
        } else if (punchOutState === today) {
            this.punchInDisabled = true;  // Punch In already recorded today
            this.punchOutDisabled = true;  // No action possible
        } else {
            this.punchInDisabled = false;  // Allow Punch In
            this.punchOutDisabled = true;   // Disable Punch Out until Punch In is made
        }
    }
}
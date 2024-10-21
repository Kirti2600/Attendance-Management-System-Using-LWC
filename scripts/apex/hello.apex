// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);

public static Attendance__c punchOutAttendance() {
   // User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Query for today's attendance record for the user
    Attendance__c attendanceRecord = [SELECT Id, Punch_In__c, Punch_Out__c 
                                       FROM Attendance__c 
                                       WHERE Employee__c = :currentUser.Id 
                                       AND CALENDAR_YEAR(Punch_In__c) = :Date.today().year()
                                       AND CALENDAR_MONTH(Punch_In__c) = :Date.today().month()
                                       LIMIT 1];

    System.debug(attendanceRecord.Punch_In__c);

    if (attendanceRecord != null && attendanceRecord.Punch_Out__c == null) {
        attendanceRecord.Punch_Out__c = DateTime.now();
        update attendanceRecord;
        return attendanceRecord;
    } else {
        throw new AuraHandledException('You have already punched out today or no punch-in record found.');
    }

    System.debug('Current User ID: ' + currentUser.Id);
    System.debug('Attendance Record: ' + attendanceRecord');
}
public with sharing class AttendanceKirtiController
{
    @AuraEnabled
    public static Attendance__c punchInAttendance() {
        // Get the user ID of the current user
        Id userId = UserInfo.getUserId();
        
        // Query the current user to retrieve the Employee_Id__c field
        User currentUser = [SELECT Employee_Id__c FROM User WHERE Id = :userId LIMIT 1];
    
        // Use the Employee_Id__c field to get the Employee__c record
        Employee__c employee = [SELECT Id FROM Employee__c WHERE Id = :currentUser.Employee_Id__c LIMIT 1];
    
        // Get the current year and month
        Integer currentYear = Date.today().year();
        Integer currentMonth = Date.today().month();
    
        // Check or create the monthly attendance record
        Monthly_Attendance__c monthlyAttendance = checkOrCreateMonthlyAttendance(employee.Id, currentYear, currentMonth);
    
        // Create the attendance record for the user
        Attendance__c attendanceRecord = new Attendance__c(
            Employee__c = employee.Id, // Set employee reference
            Punch_In__c = DateTime.now(),
            Monthly_Attendance__c = monthlyAttendance.Id
        );
    
        insert attendanceRecord; // Insert the new attendance record
        return attendanceRecord; // Return the attendance record
    }

    @AuraEnabled
    public static Attendance__c punchOutAttendance() {
        Id userId = UserInfo.getUserId();
        System.debug('Current User ID: ' + userId);
        
        // Fetch the current user's employee ID
        User currentUser = [SELECT Employee_Id__c FROM User WHERE Id = :userId LIMIT 1];
        System.debug('Employee ID from current user: ' + currentUser.Employee_Id__c);
        
        // Fetch the corresponding employee record
        Employee__c employee = [SELECT Id FROM Employee__c WHERE Id = :currentUser.Employee_Id__c LIMIT 1];
        System.debug('Employee record ID: ' + employee.Id);
        
        // Fetch attendance records for the current month and year
        List<Attendance__c> attendanceRecords = [
            SELECT Id, Punch_In__c, Punch_Out__c 
            FROM Attendance__c 
            WHERE Employee__c = :employee.Id
            AND Punch_Out__c = null
            AND CALENDAR_YEAR(Punch_In__c) = :Date.today().year()
            AND CALENDAR_MONTH(Punch_In__c) = :Date.today().month()
            ORDER BY Punch_In__c DESC
            LIMIT 1
        ];
        
        System.debug('Attendance Records Count: ' + attendanceRecords.size());
        
        if (attendanceRecords.isEmpty()) {
            System.debug('No attendance records found for this employee in the current month.');
            throw new AuraHandledException('No attendance records found for this employee in the current month.');
        }
        
        Attendance__c attendanceOne = attendanceRecords[0]; // Use the first record
        System.debug('Attendance Record ID: ' + attendanceOne.Id);
        System.debug('Punch In Time: ' + attendanceOne.Punch_In__c);
        System.debug('Punch Out Time Before: ' + attendanceOne.Punch_Out__c);
        
        // Check if Punch Out time is already set
        if (attendanceOne.Punch_Out__c == null) {
           DateTime punchOutTimeIST = DateTime.now().addHours(+5).addMinutes(+30);
            attendanceOne.Punch_Out__c = punchOutTimeIST;
           //  attendanceOne.Punch_Out__c= DateTime.now().addHours(5).addMinutes(30);
            System.debug('Punching out at: ' + attendanceOne.Punch_Out__c);
        } else {
            System.debug('Punch Out Time is already set: ' + attendanceOne.Punch_Out__c);
            throw new AuraHandledException('Punch Out Time is already set.');
        }
        
        // Try updating the attendance record
        try {
            update attendanceOne;
            System.debug('Attendance record updated successfully: ' + attendanceOne);
        } catch (DmlException e) {
            System.debug('Error updating attendance record: ' + e.getMessage());
            throw new AuraHandledException('Error updating attendance record: ' + e.getMessage());
        }
        
        return attendanceOne; // Ensure returning the updated attendance record
    }
    
       

@AuraEnabled
public static Monthly_Attendance__c checkOrCreateMonthlyAttendance(Id employeeId, Integer currentYear, Integer currentMonth) {
    // Check if the monthly attendance exists for the current month and year for the employee
    List<Monthly_Attendance__c> monthlyAttendance = [
        SELECT Id FROM Monthly_Attendance__c 
        WHERE Employee__c = :employeeId
        AND Year__c = :currentYear
        AND Month__c = :currentMonth
        LIMIT 1
    ];

    if (monthlyAttendance.isEmpty()) {
        // Create a new Monthly Attendance record if it doesn't exist
        Monthly_Attendance__c newMonthlyAttendance = new Monthly_Attendance__c(
            Employee__c = employeeId,
            Year__c = currentYear,
            Month__c = currentMonth,
            Start_Date__c = Date.today().toStartOfMonth() // Optional: Setting the start date as the 1st day of the month
        );

            insert newMonthlyAttendance; // Insert the new monthly attendance record
            return newMonthlyAttendance; // Return the newly created record
    }
           return monthlyAttendance[0];
        }
    }
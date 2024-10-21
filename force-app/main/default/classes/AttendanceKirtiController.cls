public  class AttendanceKirtiController
{
    @AuraEnabled
    public static Attendance__c punchInAttendance(Boolean isWorkFromHome) {
        // Get the user ID of the current user
        String userId = UserInfo.getUserId();
    Integer totalAbsent = 0; // Initialize total absent count
    
        // Use the Employee_Id__c field to get the Employee__c record
        Employee__c employee = [SELECT Id, Name FROM Employee__c WHERE User__c = :userId LIMIT 1];
          

       
         // Get the current year and month
        Integer currentYear = Date.today().year();
        Integer currentMonth = Date.today().month();
        Integer totalDays = Date.daysInMonth(currentYear, currentMonth);

    
        // Check or create the monthly attendance record
        Monthly_Attendance__c monthlyAttendance = checkOrCreateMonthlyAttendance(employee.Id, currentYear, currentMonth);
    
        // Create the attendance record for the user
         Attendance__c attendanceRecord = new Attendance__c();
            attendanceRecord.Employee__c = employee.Id;// Set employee reference
            attendanceRecord.Punch_In__c = DateTime.now();
            attendanceRecord.Monthly_Attendance__c = monthlyAttendance.Id;
        if(isWorkFromHome){
            attendanceRecord.Work_From_Home__c=true;            
        }
    
        
        insert attendanceRecord; // Insert the new attendance record
        
         if (isLastDayOfMonth(totalDays)) {
            totalAbsent = totalAbsent(); // Implement totalAbsent() as needed
            monthlyAttendance.Total_Absent__c = totalAbsent;
            update monthlyAttendance;
        }
        update monthlyAttendance;
        
        return attendanceRecord; // Return the attendance record
    }

    @AuraEnabled
    public static Attendance__c punchOutAttendance(string attendanceId) {
        Id userId = UserInfo.getUserId();
        System.debug('Current User ID: ' + userId);
        
        // Fetch the current user's employee ID
        User currentUser = [SELECT Id,Employee_Id__c FROM User WHERE Id = :userId LIMIT 1];
        
        // Fetch the corresponding employee record
        Employee__c employee = [SELECT Id FROM Employee__c WHERE User__c = :currentUser.Id LIMIT 1];
        System.debug('Employee record ID: ' + employee.Id);
        
        // Fetch attendance records for the current month and year
        Attendance__c attendanceRecord = [
            SELECT Id, Punch_In__c, Punch_Out__c 
            FROM Attendance__c 
            WHERE Id=:attendanceId limit 1
        ];
        
        System.debug('Attendance Records Count: ' + attendanceRecord);
        
        System.debug('Attendance Record ID: ' + attendanceRecord.Id);
        System.debug('Punch In Time: ' + attendanceRecord.Punch_In__c);
        System.debug('Punch Out Time Before: ' + attendanceRecord.Punch_Out__c);
        
        // Check if Punch Out time is already set
        if (attendanceRecord.Punch_Out__c == null) {
           DateTime punchOutTimeIST = DateTime.now();
            attendanceRecord.Punch_Out__c = punchOutTimeIST;
           //  attendanceOne.Punch_Out__c= DateTime.now().addHours(5).addMinutes(30);
            System.debug('Punching out at: ' + attendanceRecord.Punch_Out__c);
        } else {
            System.debug('Punch Out Time is already set: ' + attendanceRecord.Punch_Out__c);
            throw new AuraHandledException('Punch Out Time is already set.');
        }
        
        // Try updating the attendance record
        try {
            update attendanceRecord;
            System.debug('Attendance record updated successfully: ' + attendanceRecord);
        } catch (DmlException e) {
            System.debug('Error updating attendance record: ' + e.getMessage());
            throw new AuraHandledException('Error updating attendance record: ' + e.getMessage());
        }
        
        return attendanceRecord; // Ensure returning the updated attendance record
    }
    
       
@AuraEnabled
public static Monthly_Attendance__c checkOrCreateMonthlyAttendance(Id employeeId, Integer currentYear, Integer currentMonth) {
    // Get the total days in the current month

    // Check if the monthly attendance exists for the current month and year for the employee
    List<Monthly_Attendance__c> monthlyAttendance = [
        SELECT Id, Total_Present__c, Total_Absent__c 
        FROM Monthly_Attendance__c 
        WHERE Employee__c = :employeeId
        AND Year__c = :currentYear
        AND Month__c = :currentMonth
        LIMIT 1
    ];

    // If no monthly attendance record exists, create one
    if (monthlyAttendance.isEmpty()) {
        // Query the Holiday object for holidays in the current month
        List<Holiday__c> holidays = [
            SELECT Id 
            FROM Holiday__c 
            WHERE CALENDAR_YEAR(Date__c) = :currentYear 
            AND CALENDAR_MONTH(Date__c) = :currentMonth
        ];
        Integer totalHolidays = holidays.size();
        Integer totalWeekends = totalWeekends(); // Make sure to implement this method

        // Create a new Monthly Attendance record
        Monthly_Attendance__c newMonthlyAttendance = new Monthly_Attendance__c(
            Employee__c = employeeId,
            Year__c = currentYear,
            Month__c = currentMonth,
            Holiday__c = totalHolidays,
            Weekends__c = totalWeekends,
            Total_Present__c = 1, // Start with 1 present for the current day
            Start_Date__c = Date.today().toStartOfMonth()
        );

        insert newMonthlyAttendance;

       

        return newMonthlyAttendance; // Return the newly created record
    }

    // Update the existing monthly attendance record
    Monthly_Attendance__c existingAttendance = monthlyAttendance[0];
    existingAttendance.Total_Present__c += 1; // Increment present count

    return existingAttendance; // Return the updated record
}

// Helper method to check if today is the last day of the month
private static Boolean isLastDayOfMonth(Integer totalDays) {
   // return Date.today().day() == totalDays;
    return true;
}

    @auraEnabled
    public static Attendance__c checkAttendanceForUser(){
         Id userId = UserInfo.getUserId();
        system.debug(userId);
        // Query the current user to retrieve the Employee_Id__c field
        User currentUser = [SELECT id,username, Employee_Id__c FROM User WHERE Id = :userId LIMIT 1];
        system.debug(currentUser);
        // Use the Employee_Id__c field to get the Employee__c record
        Employee__c employee = [SELECT Id FROM Employee__c WHERE User__c = :currentUser.Id LIMIT 1];
        system.debug(employee);
        list<Attendance__c> attendanceRecord=[select id,Punch_In__c,Punch_Out__c,Work_From_Home__c from Attendance__c WHERE Employee__c=:employee.id AND CreatedDate=TODAY];
       system.debug(attendanceRecord);
        if(!attendanceRecord.isEmpty()){
            return attendanceRecord[0];
        }
        else{
            return new Attendance__c();
        }
    }
public static Integer totalWeekends() {
    Integer weekendCount = 0;
    Integer year = Date.today().year();
    Integer month = Date.today().month();
    Integer numberDays = Date.daysInMonth(year, month);
    
    for (Integer day = 1; day <= numberDays; day++) {
        // Create a Date instance for each day
        Date myDate = Date.newInstance(year, month, day);
        
        // Convert Date to DateTime (using 00:00:00 for the time)
        DateTime myDateTime = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));

        // Get the day of the week (1=Monday, ..., 7=Sunday)
        Integer dayOfWeek = Integer.valueOf(myDateTime.format('u').substring(0, 1));
        
        // Check if the day is Saturday (6) or Sunday (7)
        if (dayOfWeek == 6 || dayOfWeek == 7) {
            weekendCount++;
        }
    }
    
    return weekendCount;
}
  public static Integer totalAbsent() {
    Integer currentYear = Date.today().year();
    Integer currentMonth = Date.today().month();
    Integer totalAbsents = 0;
    Integer totalHolidaysInWeekend = 0;
    Id userId = UserInfo.getUserId();

    // Query the current user to retrieve the Employee_Id__c field
    User currentUser = [SELECT Id, Employee_Id__c FROM User WHERE Id = :userId LIMIT 1];

    // Use the Employee_Id__c field to get the Employee__c record
    Employee__c employee = [SELECT Id FROM Employee__c WHERE User__c = :currentUser.Id LIMIT 1];

    List<Monthly_Attendance__c> monthlyAttendance = [
        SELECT Id, Total_Present__c, Total_Absent__c, Weekends__c, Holiday__c 
        FROM Monthly_Attendance__c 
        WHERE Employee__c = :employee.Id
        AND Year__c = :currentYear
        AND Month__c = :currentMonth
        LIMIT 1
    ];

    List<Attendance__c> attendanceRecords = [
        SELECT Id, Punch_In__c, Punch_Out__c, Work_From_Home__c 
        FROM Attendance__c 
        WHERE Employee__c = :employee.Id AND CreatedDate = TODAY
    ];

    // Query all holidays
    List<Holiday__c> holidaysRecord = [SELECT Id, Date__c FROM Holiday__c];

    // Count holidays that fall on weekends
    for (Holiday__c holiday : holidaysRecord) {
        Date myDate = holiday.Date__c;

        // Convert Date to DateTime (using 00:00:00 for the time)
        DateTime myDateTime = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));

        // Get the day of the week (1=Monday, ..., 7=Sunday)
        Integer dayOfWeek = Integer.valueOf(myDateTime.format('u').substring(0, 1));

        // Check if the day is Saturday (6) or Sunday (7)
        if (dayOfWeek == 6 || dayOfWeek == 7) {
            totalHolidaysInWeekend++;
        }
    }

    // Get the total days in the current month
    Integer totalDays = Date.daysInMonth(currentYear, currentMonth);

    // Ensure that we correctly retrieve Integer values from the Monthly Attendance record
    Integer weekends = monthlyAttendance.isEmpty() ? 0 : monthlyAttendance[0].Weekends__c.intValue();
    Integer holidays = monthlyAttendance.isEmpty() ? 0 : monthlyAttendance[0].Holiday__c.intValue();

    // Calculate total absents
    totalAbsents = totalDays - attendanceRecords.size() - weekends - holidays + totalHolidaysInWeekend;
   system.debug(totalDays+' '+ attendanceRecords.size()+' '+weekends+' '+holidays+' '+totalHolidaysInWeekend);
    return totalAbsents;
}


    }
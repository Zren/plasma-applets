import QtQuick 2.0

// This is a pure QML version of
// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/calendar.h
// https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/calendar.cpp
// We do this to have a stable base since these files are constantly updating, and
// any errors from incompatibility crash plasmashell with no stacktraces.
// We also do this to use JSON Objects instead of DayModel so we're not limited to it's schema.
Item {
    // enum Type Q_DECLARE_FLAGS
    property int holiday: 1
    property int event: 2
    property int todo: 4
    property int journal: 8

    // enum DateMatchingPrecision
    property int matchYear: 0
    property int matchYearAndMonth: 1
    property int matchYearMonthAndDay: 2

    property date displayedDate: new Date()
    property date today: new Date()
    property int types: holiday | event | todo | journal
    property int days: 0
    property int weeks: 0
    property int firstDayOfWeek: Qt.locale().firstDayOfWeek
    readonly property int year: displayedDate.getFullYear()
    property string errorMessage: ''
    property string monthName: Qt.locale().standaloneMonthName(displayedDate.getMonth())
    property int currentWeek: getWeekNumber(today)


    function isLeapYear(y) {
        // https://github.com/radekp/qt/blob/198b974587ba9751a2bdc73464c05c164d49f10c/src/corelib/tools/qdatetime.cpp#L1365
        if (year < 1582) {
            return Math.abs(y) % 4 == 0;
        } else {
            return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
        }
    }

    function getWeekNumber(date) {
        // 1-52 (or 53)
        // http://doc.qt.io/qt-5/qdate.html#weekNumber
        // https://github.com/radekp/qt/blob/198b974587ba9751a2bdc73464c05c164d49f10c/src/corelib/tools/qdatetime.cpp#L468
        var year = date.getFullYear();
        var yday = getDayOfYear(date);
        var wday = date.getDay();
        var w;
        for (;;) {
            var len = isLeapYear(year) ? 366 : 365;
            // What yday (-3 ... 3) does the ISO year begin on?
            var bot = ((yday + 11 - wday) % 7) - 3;
            // What yday does the NEXT ISO year begin on?
            var top = bot - (len % 7);
            if (top < -3)
                top += 7;
            top += len;
            if (yday >= top) {
                ++year;
                w = 1;
                break;
            }
            if (yday >= bot) {
                w = 1 + ((yday - bot) / 7);
                break;
            }
            --year;
            yday += isLeapYear(year) ? 366 : 365;
        }

        return w;
    }

    function getDayOfYear(date) {
        // 1-365 (or 366)
        // https://github.com/radekp/qt/blob/198b974587ba9751a2bdc73464c05c164d49f10c/src/corelib/tools/qdatetime.cpp#L401
        // http://stackoverflow.com/a/8619946/947742
        var start = new Date(date.getFullYear(), 0, 0);
        var diff = date - start;
        var oneDay = 1000 * 60 * 60 * 24;
        var day = Math.floor(diff / oneDay);
        return day;
    }

    function getShortDayName(weekDay) {
        // https://github.com/radekp/qt/blob/198b974587ba9751a2bdc73464c05c164d49f10c/src/corelib/tools/qdatetime.cpp#L658
        return Qt.locale().standaloneDayName(weekDay, Locale.ShortFormat);
    }

    ListModel {
        id: weeksModel
    }

    ListModel {
        id: daysModel
    }

    onDisplayedDateChanged: {
        console.log('onDisplayedDateChanged', displayedDate)
        updateData()
    }

    onTodayChanged: {
        console.log('onTodayChanged', today)
        updateData()
    }

    onMonthNameChanged: {
        console.log('onMonthNameChanged', monthName)
    }

    onYearChanged: {
        console.log('onYearChanged', year)
    }

    onTypesChanged: {
        console.log('onTypesChanged', types)
    }

    onDaysChanged: {
        console.log('onDaysChanged', days)
        updateData()
    }

    onWeeksChanged: {
        console.log('onWeeksChanged', weeks)
        updateData()
    }

    onFirstDayOfWeekChanged: {
        console.log('onFirstDayOfWeekChanged', firstDayOfWeek)
        updateData()
    }

    function resetToToday() {
        displayedDate = today
    }

    function dayName(weekDay) {
        return getShortDayName(weekDay);
    }

    function updateData() {
        console.log('updateData')
        updateMonthOverview()
    }

    // http://stackoverflow.com/questions/1184334/get-number-days-in-a-specified-month-using-javascript
    function daysInMonth(year, month) {
        return new Date(year, month+1, 0).getDate();
    }

    // Implement Calendar.updateData()
    // https://github.com/KDE/plasma-framework/blob/master/src/declarativeimports/calendar/calendar.cpp#L215
    function updateMonthOverview() {
        var date = calendarBackend.displayedDate;
        var day = date.getDate();
        var month = date.getMonth(); // 0-11
        var year = date.getFullYear();
        // console.log('displayedDate', date);
        // console.log(day, month+1, year);

        daysModel.clear();
        var totalDays = calendarBackend.days * calendarBackend.weeks;
        var daysBeforeCurrentMonth = 0;
        var daysAfterCurrentMonth = 0;
        var firstDay = new Date(year, month, 1);
        var firstDayOfWeek = firstDay.getDay() == 0 ? 7 : firstDay.getDay();
        if (calendarBackend.firstDayOfWeek < firstDayOfWeek) {
            daysBeforeCurrentMonth = firstDayOfWeek - calendarBackend.firstDayOfWeek;
        } else {
            daysBeforeCurrentMonth = calendarBackend.days - (calendarBackend.firstDayOfWeek - firstDayOfWeek);
        }

        var daysInCurrentMonth = daysInMonth(year, month);
        var daysThusFar = daysBeforeCurrentMonth + daysInCurrentMonth;
        if (daysThusFar < totalDays) {
            daysAfterCurrentMonth = totalDays - daysThusFar;
        }
        // console.log(daysBeforeCurrentMonth, daysInCurrentMonth, daysAfterCurrentMonth)
        // console.log(totalDays, daysThusFar);

        if (daysBeforeCurrentMonth > 0) {
            var previousMonth = new Date(year, month-1, 1);
            var daysInPreviousMonth = daysInMonth(year, month-1);
            for (var i = 0; i < daysBeforeCurrentMonth; i++) {
                var dayData = {};
                dayData.isCurrent = false;
                dayData.dayNumber = daysInPreviousMonth - (daysBeforeCurrentMonth - (i + 1));
                dayData.monthNumber = previousMonth.getMonth() + 1;
                dayData.yearNumber = previousMonth.getFullYear();
                dayData.showEventBadge = false;
                dayData.events = [];
                daysModel.append(dayData);
            }
        }

        for (var i = 0; i < daysInCurrentMonth; i++) {
            var dayData = {};
            dayData.isCurrent = true;
            dayData.dayNumber = i + 1;
            dayData.monthNumber = month + 1;
            dayData.yearNumber = year;
            dayData.showEventBadge = false;
            dayData.events = [];
            daysModel.append(dayData);
        }

        if (daysAfterCurrentMonth > 0) {
            var nextMonth = new Date(year, month+1, 1);
            for (var i = 0; i < daysAfterCurrentMonth; i++) {
                var dayData = {};
                dayData.isCurrent = false;
                dayData.dayNumber = i + 1;
                dayData.monthNumber = nextMonth.getMonth() + 1;
                dayData.yearNumber = nextMonth.getFullYear();
                dayData.showEventBadge = false;
                dayData.events = [];
                daysModel.append(dayData);
            }
        }
    }

    Component.onCompleted: {

        // Tests
        var date = new Date(displayedDate);
        date.setDate(date.getDate() + 1)
        displayedDate = date;

        date = new Date(displayedDate);
        date.setMonth(date.getMonth() + 1)
        displayedDate = date;

        date = new Date(displayedDate);
        date.setFullYear(date.getFullYear() + 1)
        displayedDate = date;
    }
}
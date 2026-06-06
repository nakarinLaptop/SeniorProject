let chart;
//select day
function loadChartData(days) {
    return fetch('dashboard.jsp?action=chart&days=' + days)
        .then(function(response) { return response.json(); });
}

function changeRange(days) {
    loadChartData(parseInt(days)).then(function(data) {
        chart.data.labels = data.labels;
        chart.data.datasets[0].data = data.home;
        chart.data.datasets[1].data = data.hospital;
        chart.update();
    });
}

function updateStats(selectedDate) {
    const day   = selectedDate.getDate();
    const month = selectedDate.getMonth() + 1;
    const year  = selectedDate.getFullYear();
    const dateString   = day + '/' + month + '/' + year;
    const dbDateString = year + '-' + (month < 10 ? '0' + month : month) + '-' + (day < 10 ? '0' + day : day);

    document.querySelector('.statsContainer h2').textContent = 'สถิติข้อมูลการทำนายสถานที่ตรวจสุขภาพ - วันที่ ' + dateString;

    fetch('dashboard.jsp?action=stats&date=' + dbDateString)
        .then(function(response) { return response.json(); })
        .then(function(data) {
            document.getElementById('stat_total_predict').textContent = data.totalPredict;
            document.getElementById('stat_home').textContent          = data.homeCount;
            document.getElementById('stat_hospital').textContent      = data.hospitalCount;
            document.getElementById('stat_agree').textContent         = data.agreeCount;
            document.getElementById('stat_disagree').textContent      = data.disagreeCount;
            document.getElementById('stat_agree_rate').textContent    = parseFloat(data.agreeRate).toFixed(2);
        });
}

document.addEventListener("DOMContentLoaded", function () {

    const ctx = document.getElementById("homeHospitalLineChart").getContext("2d");
    chart = new Chart(ctx, {
        type: "line",
        data: {
            labels: [],
            datasets: [
                {
                    label: "ตรวจที่บ้าน",
                    data: [],
                    borderColor: "#3b82f6",
                    backgroundColor: "rgba(59,130,246,0.2)",
                    fill: true,
                    tension: 0.3
                },
                {
                    label: "ตรวจโรงพยาบาล",
                    data: [],
                    borderColor: "#10b981",
                    backgroundColor: "rgba(16,185,129,0.2)",
                    fill: true,
                    tension: 0.3
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false
        }
    });

    loadChartData(7).then(function(data) {
        chart.data.labels = data.labels;
        chart.data.datasets[0].data = data.home;
        chart.data.datasets[1].data = data.hospital;
        chart.update();
    });

    const calendarGrid = document.querySelector('.calendar-grid');
    const monthYear = document.getElementById('monthYear');
    const today = new Date(SERVER_DATE);

    const DAY_NAMES = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    const monthNames = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    let currentMonth = today.getMonth();
    let currentYear  = today.getFullYear();

    function drawCalendar(month, year) {
        calendarGrid.innerHTML = '';
        DAY_NAMES.forEach(function(name) {
            const dn = document.createElement('div');
            dn.classList.add('day-name');
            dn.textContent = name;
            calendarGrid.appendChild(dn);
        });

        monthYear.textContent = monthNames[month] + ' ' + (year);

        const daysInMonth    = new Date(year, month + 1, 0).getDate();
        const firstDayOfWeek = (new Date(year, month, 1).getDay() + 6) % 7;
        //add space before first day
        for (let i = 0; i < firstDayOfWeek; i++) {
            const empty = document.createElement('div');
            empty.classList.add('day', 'empty');
            calendarGrid.appendChild(empty);
        }

        for (let dayNumber = 1; dayNumber <= daysInMonth; dayNumber++) {
            const dayBox = document.createElement('div');
            dayBox.classList.add('day');
            dayBox.textContent = dayNumber;

            if (dayNumber === today.getDate() && month === today.getMonth() && year === today.getFullYear()) {
                dayBox.classList.add('today');
            }

            dayBox.addEventListener('click', function () {
                calendarGrid.querySelectorAll('.day').forEach(function(d) { d.classList.remove('selected-day'); });
                this.classList.add('selected-day');
                updateStats(new Date(year, month, dayNumber));
            });

            calendarGrid.appendChild(dayBox);
        }
    }

    drawCalendar(currentMonth, currentYear);

    document.getElementById('prevMonth').addEventListener('click', function () {
        currentMonth--;
        if (currentMonth < 0) { currentMonth = 11; currentYear--; }
        drawCalendar(currentMonth, currentYear);
    });

    document.getElementById('nextMonth').addEventListener('click', function () {
        currentMonth++;
        if (currentMonth > 11) { currentMonth = 0; currentYear++; }
        drawCalendar(currentMonth, currentYear);
    });
});





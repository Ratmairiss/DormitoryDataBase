-- =============================================
-- Запрос 1.1
-- Найти студентов, которые проживали в комнате А (14881), 
-- имеют семейный статус Б (2) и которым начислена сумма не менее С (500)
-- =============================================
SELECT
    s.id_Student AS "ID студента",
    s.Name AS "Имя",
    s.Surname AS "Фамилия",
    SUM(
        DATEDIFF(lr.Date_eviction, lr.Date_check_in) * r.Price_for_a_day / rl.occupants
    ) AS "Сумма начислений"
FROM Student AS s
JOIN Living_in_room AS lr ON s.id_Student = lr.id_Student
JOIN Room AS r ON lr.id_Room = r.id_Room
JOIN (
    SELECT
        lr1.id_Living_in_room,
        COUNT(lr2.id_Living_in_room) AS occupants
    FROM Living_in_room AS lr1
    JOIN Living_in_room AS lr2
      ON lr1.id_Room = lr2.id_Room
     AND lr2.Date_check_in <= lr1.Date_eviction
     AND lr2.Date_eviction >= lr1.Date_check_in
    GROUP BY lr1.id_Living_in_room
) AS rl ON lr.id_Living_in_room = rl.id_Living_in_room
WHERE lr.id_Room = 14881
  AND s.id_Family_status = 2
GROUP BY s.id_Student, s.Name, s.Surname
HAVING SUM(
    DATEDIFF(lr.Date_eviction, lr.Date_check_in) * r.Price_for_a_day / rl.occupants
) >= 500;

-- =============================================
-- Запрос 1.2
-- Найти студентов, которые проживали в комнате А (14881), 
-- имеют семейный статус Б (2) и у которых нет долга по оплате
-- =============================================
SELECT
    s.id_Student AS "ID студента",
    s.Name AS "Имя",
    s.Surname AS "Фамилия",
    SUM(
        DATEDIFF(lr.Date_eviction, lr.Date_check_in) * r.Price_for_a_day / rl.occupants
    ) AS "Сумма начислений",
    SUM(p.Amount) AS "Оплаченная сумма"
FROM Student AS s
JOIN Living_in_room AS lr ON s.id_Student = lr.id_Student
JOIN Room AS r ON lr.id_Room = r.id_Room
JOIN (
    SELECT
        lr1.id_Living_in_room,
        COUNT(lr2.id_Living_in_room) AS occupants
    FROM Living_in_room AS lr1
    JOIN Living_in_room AS lr2
      ON lr1.id_Room = lr2.id_Room
     AND lr2.Date_check_in <= lr1.Date_eviction
     AND lr2.Date_eviction >= lr1.Date_check_in
    GROUP BY lr1.id_Living_in_room
) AS rl ON lr.id_Living_in_room = rl.id_Living_in_room
JOIN Paid_amount AS p ON s.id_Student = p.id_Student
WHERE lr.id_Room = 14881
  AND s.id_Family_status = 2
GROUP BY s.id_Student, s.Name, s.Surname
HAVING (
    SUM(DATEDIFF(lr.Date_eviction, lr.Date_check_in) * r.Price_for_a_day / rl.occupants)
    - SUM(p.Amount)
) <= 0;

-- =============================================
-- Запрос 2
-- Для комнаты А (1433) посчитать количество студентов, 
-- у которых была регистрация в общежитии Б (23)
-- =============================================
SELECT 
    lr.id_Room AS "ID Комнаты",
    d.name AS "Название общежития",
    COUNT(s.id_Student) AS "Количество студентов"
FROM Living_in_room AS lr
JOIN Student AS s ON lr.id_Student = s.id_Student
JOIN Registration AS reg ON s.id_Student = reg.id_Student
JOIN Dormitory as d ON reg.id_Address = d.id_Address
WHERE lr.id_Room = 1433
  AND d.id_Dormitory = 23;

-- =============================================
-- Запрос 3
-- Для каждого коменданта посчитать количество студентов, 
-- которых он учитывал и общую сумму платежей
-- =============================================
SELECT  commandant.Name as "Имя",
       commandant.Surname as "Фамилия",
       COUNT(DISTINCT paid_amount.id_Student) AS "Количество студентов",
       SUM(paid_amount.Amount) AS "Оплаченная сумма"
FROM commandant
JOIN paid_amount ON commandant.id_Commandant = paid_amount.id_Commandant
GROUP BY commandant.id_Commandant;

-- =============================================
-- Запрос 4
-- Вывести количество студентов и число комнат, 
-- в которых проживало такое количество студентов
-- =============================================
SELECT
    rooms.studAmt AS "Число студентов",
    COUNT(rooms.id_Room) AS "Число комнат"
FROM (
    SELECT
        room.id_Room,
        COUNT(living.id_Student) AS studAmt
    FROM Room AS room
    JOIN Living_in_room AS living ON room.id_Room = living.id_Room
    GROUP BY room.id_Room
) AS rooms
GROUP BY rooms.studAmt;

-- =============================================
-- Запрос 5.1
-- Найти общежития с наибольшим числом комнат
-- =============================================
SELECT
    dorm.Name AS "Название общежития",
    COUNT(room.id_Room) AS num_rooms
FROM Dormitory AS dorm
JOIN Area AS area ON dorm.id_Dormitory = area.id_Dormitory
JOIN Room AS room ON area.id_Area = room.id_Area
GROUP BY dorm.id_Dormitory, dorm.Name
HAVING COUNT(room.id_Room) = (
    SELECT MAX(room_count)
    FROM (
        SELECT COUNT(r.id_Room) AS room_count
        FROM Dormitory d
        JOIN Area a ON d.id_Dormitory = a.id_Dormitory
        JOIN Room r ON a.id_Area = r.id_Area
        GROUP BY d.id_Dormitory
    ) AS max_counts
)
OR COUNT(room.id_Room) = (
    SELECT MAX(room_count)
    FROM (
        SELECT COUNT(r.id_Room) AS room_count
        FROM Dormitory d
        JOIN Area a ON d.id_Dormitory = a.id_Dormitory
        JOIN Room r ON a.id_Area = r.id_Area
        GROUP BY d.id_Dormitory
        HAVING COUNT(r.id_Room) < (
            SELECT MAX(room_count)
            FROM (
                SELECT COUNT(r2.id_Room) AS room_count
                FROM Dormitory d2
                JOIN Area a2 ON d2.id_Dormitory = a2.id_Dormitory
                JOIN Room r2 ON a2.id_Area = r2.id_Area
                GROUP BY d2.id_Dormitory
            ) AS first_max
        )
    ) AS second_max
);

-- =============================================
-- Запрос 5.2
-- Найти общежития с наименьшим числом комнат
-- =============================================
SELECT
    dorm.Name AS "Название общежития",
    COUNT(room.id_Room) AS num_rooms
FROM Dormitory AS dorm
JOIN Area AS area ON dorm.id_Dormitory = area.id_Dormitory
JOIN Room AS room ON area.id_Area = room.id_Area
GROUP BY dorm.id_Dormitory, dorm.Name
HAVING COUNT(room.id_Room) = (
    SELECT MIN(room_count)
    FROM (
        SELECT COUNT(r.id_Room) AS room_count
        FROM Dormitory d
        JOIN Area a ON d.id_Dormitory = a.id_Dormitory
        JOIN Room r ON a.id_Area = r.id_Area
        GROUP BY d.id_Dormitory
    ) AS min_counts
)
OR COUNT(room.id_Room) = (
    SELECT MIN(room_count)
    FROM (
        SELECT COUNT(r.id_Room) AS room_count
        FROM Dormitory d
        JOIN Area a ON d.id_Dormitory = a.id_Dormitory
        JOIN Room r ON a.id_Area = r.id_Area
        GROUP BY d.id_Dormitory
        HAVING COUNT(r.id_Room) > (
            SELECT MIN(room_count)
            FROM (
                SELECT COUNT(r2.id_Room) AS room_count
                FROM Dormitory d2
                JOIN Area a2 ON d2.id_Dormitory = a2.id_Dormitory
                JOIN Room r2 ON a2.id_Area = r2.id_Area
                GROUP BY d2.id_Dormitory
            ) AS first_min
        )
    ) AS second_min
);

-- =============================================
-- Запрос 6
-- Найти студентов, оплативших больше чем студент А (2553)
-- =============================================
SELECT
    s.id_Student AS "ID студента",
    s.Name AS "Имя",
    s.Surname AS "Фамилия",
    SUM(p.Amount) AS "Сумма платежей"
FROM Student AS s
JOIN Paid_amount AS p ON s.id_Student = p.id_Student
GROUP BY s.id_Student, s.Name, s.Surname
HAVING SUM(p.Amount) > (
    SELECT SUM(p2.Amount)
    FROM Paid_amount AS p2
    WHERE p2.id_Student = 2553
);

-- =============================================
-- Запрос 7
-- Найти комнаты, в которых не проживало ни одного студента с семейным положением А (2)
-- =============================================
SELECT
    r.id_Room AS "ID комнаты",
    r.Number AS "Номер"
FROM Room AS r
WHERE NOT EXISTS (
    SELECT r.id_Room
    FROM Living_in_room AS lr
    JOIN Student AS s ON lr.id_Student = s.id_Student
    WHERE lr.id_Room = r.id_Room
      AND s.id_Family_status = 2
);

-- =============================================
-- Запрос 8
-- Для каждого общежития и каждого семейного положения 
-- посчитать количество проживаний студентов
-- =============================================
SELECT
    fs.Name as "Название семейного пол.",
    d.Name as "Название общ.",
    IFNULL(count(s.id_Student),0) as "Количество проживаний"
FROM Family_status AS fs
CROSS JOIN Dormitory AS d
JOIN Area AS a ON a.id_Dormitory = d.id_Dormitory
JOIN Room AS r ON r.id_Area = a.id_Area
JOIN Living_in_room AS lr ON lr.id_Room = r.id_Room
LEFT JOIN Student AS s ON s.id_Student = lr.id_Student and fs.id_Family_status = s.id_Family_status
GROUP BY fs.id_Family_status, d.id_Dormitory;


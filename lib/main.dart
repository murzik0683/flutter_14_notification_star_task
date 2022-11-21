import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:async/async.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const StarTask(),
    );
  }
}

class StarTask extends StatefulWidget {
  const StarTask({Key? key}) : super(key: key);

  @override
  State<StarTask> createState() => _StarTaskPageState();
}

class _StarTaskPageState extends State<StarTask> {
  late FlutterLocalNotificationsPlugin localNotificationsStar;

  bool remindMe = false;
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    const androidInitialize = AndroidInitializationSettings('ic_launcher');
    //объект для IOS настроек
    const iOSInitialize = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    // общая инициализация
    const initializationSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);

    //мы создаем локальное уведомление
    localNotificationsStar = FlutterLocalNotificationsPlugin();
    localNotificationsStar.initialize(initializationSettings);
  }

  Timer? _timer;
  int? _start = 0;
  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (_) {
        if (_start == 0) {
          setState(() {
            _timer!.cancel();
          });
        } else {
          setState(() {
            _start = _start! - 1;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(
            style: ButtonStyle(
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30))),
                backgroundColor:
                    MaterialStateProperty.all(Colors.purple.shade200)),
            onPressed: () {},
            child: SwitchListTile(
              contentPadding: const EdgeInsets.all(0),
              value: remindMe,
              title: Text(
                remindMe ? 'Запланировано!' : 'Запланируй уведомление!',
                style: const TextStyle(color: Colors.white),
              ),
              onChanged: (newValue) async {
                tz.initializeTimeZones();
                final String timeZoneName =
                    await FlutterNativeTimezone.getLocalTimezone();
                tz.setLocalLocation(tz.getLocation(timeZoneName));
                //выбор времени
//https://question-it.com/questions/6947596/dart-flutter-kak-sravnit-dva-vremeni-timeofday?ysclid=lalkzboi8y355445500
                DateTime? newDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 2),
                );

                TimeOfDay? newTime2 = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );

                _startTimer();
                setState(() {
                  if (newValue) {
                    //newTime == null, если пользователь при выборе времени нажмет Отмена,
                    //иначе уведомления будут показываться в выбранное время
                    if (newTime2 != null && newDate != null) {
                      selectedTime = newTime2;
                      selectedDate = newDate;

                      print('newDate $newDate');
                      print('newTime2 $newTime2');
                      const androidDetails = AndroidNotificationDetails(
                        "id_star",
                        "title_star",
                        importance: Importance.high,
                        playSound: true,
                        sound: RawResourceAndroidNotificationSound('sound'),
                        largeIcon: DrawableResourceAndroidBitmap(
                            '@drawable/ic_launcher'),
                        styleInformation: MediaStyleInformation(),
                        color: Color.fromARGB(255, 255, 0, 0),
                      );

                      const iosDetails = DarwinNotificationDetails();
                      const generalNotificationDetails = NotificationDetails(
                          android: androidDetails, iOS: iosDetails);
                      localNotificationsStar.zonedSchedule(
                          11,
                          'Звездочка',
                          '',
                          nextInstanceOfChosenTime2(selectedDate, selectedTime),
                          generalNotificationDetails,
                          androidAllowWhileIdle: true,
                          uiLocalNotificationDateInterpretation:
                              UILocalNotificationDateInterpretation
                                  .absoluteTime,
                          matchDateTimeComponents:
                              DateTimeComponents.dayOfWeekAndTime);
                    }

                    remindMe = newValue;
                    print('remindMe $remindMe');
                    print('newValue $newValue');
                    print(TimeOfDay.now());

                    final now = DateTime.now();

                    int endTimeInt = (selectedDate.day * 24 * 60 +
                            selectedTime.hour * 60 +
                            selectedTime.minute) *
                        60;
                    int startTimeInt =
                        (now.day * 24 * 60 + now.hour * 60 + now.minute) * 60;
                    int dif = endTimeInt - startTimeInt;
                    _start = dif;
                    print('startTimeInt $startTimeInt');
                    print('endTimeInt $endTimeInt');
                    print('dif $dif');

                    RestartableTimer(Duration(seconds: dif), (() {
                      setState(() {
                        remindMe = false;
                        newValue = false;
                        print('new remindMe $remindMe');
                        print('new newValue $newValue');
                      });
                    }));
                  }
                });
              },
            ),
          ),
          Container(
              child: remindMe
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 15),
                        const Icon(Icons.calendar_month,
                            size: 20, color: Colors.purple),
                        const SizedBox(width: 5),
                        Text(
                          DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ).toString().substring(0, 10),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 15),
                        const Icon(Icons.watch_later,
                            size: 20, color: Colors.purple),
                        const SizedBox(width: 5),
                        Text(
                          DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ).toString().substring(11, 16),
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 25),
                        const Icon(Icons.timer_outlined,
                            size: 20, color: Colors.purple),
                        const SizedBox(width: 5),
                        Text('$_start seconds'),
                      ],
                    )
                  : null),
          SizedBox(
            height: remindMe ? 10.0 : 0.0,
          ),
        ]),
      ),
    );
  }

  //рассчёт следующего времени для ежедневного уведомления в выбранное время
  tz.TZDateTime nextInstanceOfChosenTime2(DateTime date, TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, date.year, date.month, date.day, time.hour, time.minute);

    // if (scheduledDate.isBefore(now)) {
    //   scheduledDate = scheduledDate.add(const Duration(days: 1));
    // }
    return scheduledDate;
  }
}

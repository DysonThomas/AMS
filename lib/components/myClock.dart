import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Simple Live Clock Widget
class LiveClock extends StatefulWidget {
  final TextStyle? timeStyle;
  final TextStyle? dateStyle;
  final bool showSeconds;
  final bool showDate;
  final bool is24HourFormat;

  const LiveClock({
    Key? key,
    this.timeStyle,
    this.dateStyle,
    this.showSeconds = true,
    this.showDate = true,
    this.is24HourFormat = false,
  }) : super(key: key);

  @override
  _LiveClockState createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  String _formatTime(DateTime time) {
    if (widget.is24HourFormat) {
      return widget.showSeconds
          ? DateFormat('HH:mm:ss').format(time)
          : DateFormat('HH:mm').format(time);
    } else {
      return widget.showSeconds
          ? DateFormat('hh:mm:ss a').format(time)
          : DateFormat('hh:mm a').format(time);
    }
  }

  String _formatDate(DateTime time) {
    return DateFormat('EEEE, MMMM d, yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatTime(_currentTime),
          style: widget.timeStyle ?? TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: Colors.red,
          ),
        ),
        if (widget.showDate) ...[
          SizedBox(height: 8),
          Text(
            _formatDate(_currentTime),
            style: widget.dateStyle ?? TextStyle(
              fontSize: 18,
              color: Colors.red[200]
            ),
          ),
        ],
      ],
    );
  }
}

// Digital Clock Widget with Background
class DigitalClockWidget extends StatefulWidget {
  @override
  _DigitalClockWidgetState createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends State<DigitalClockWidget> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3C72),
            Color(0xFF2A5298),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LiveClock(
        timeStyle: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'monospace',
        ),
        dateStyle: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
      ),
    );
  }
}

// Analog Clock Widget
class AnalogClock extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? hourHandColor;
  final Color? minuteHandColor;
  final Color? secondHandColor;

  const AnalogClock({
    Key? key,
    this.size = 200,
    this.backgroundColor,
    this.hourHandColor,
    this.minuteHandColor,
    this.secondHandColor,
  }) : super(key: key);

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: ClockPainter(
          time: _currentTime,
          backgroundColor: widget.backgroundColor ?? Colors.white,
          hourHandColor: widget.hourHandColor ?? Colors.black,
          minuteHandColor: widget.minuteHandColor ?? Colors.black,
          secondHandColor: widget.secondHandColor ?? Colors.red,
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime time;
  final Color backgroundColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;

  ClockPainter({
    required this.time,
    required this.backgroundColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw hour markers
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * (3.14159 / 180);
      final startPoint = Offset(
        center.dx + (radius - 20) * Math.cos(angle),
        center.dy + (radius - 20) * Math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius - 10) * Math.cos(angle),
        center.dy + (radius - 10) * Math.sin(angle),
      );

      final markerPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;
      canvas.drawLine(startPoint, endPoint, markerPaint);
    }

    // Calculate angles
    final secondAngle = (time.second * 6 - 90) * (3.14159 / 180);
    final minuteAngle = (time.minute * 6 - 90) * (3.14159 / 180);
    final hourAngle = ((time.hour % 12) * 30 + time.minute * 0.5 - 90) * (3.14159 / 180);

    // Draw hour hand
    final hourHandPaint = Paint()
      ..color = hourHandColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.5 * Math.cos(hourAngle),
        center.dy + radius * 0.5 * Math.sin(hourAngle),
      ),
      hourHandPaint,
    );

    // Draw minute hand
    final minuteHandPaint = Paint()
      ..color = minuteHandColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.7 * Math.cos(minuteAngle),
        center.dy + radius * 0.7 * Math.sin(minuteAngle),
      ),
      minuteHandPaint,
    );

    // Draw second hand
    final secondHandPaint = Paint()
      ..color = secondHandColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.8 * Math.cos(secondAngle),
        center.dy + radius * 0.8 * Math.sin(secondAngle),
      ),
      secondHandPaint,
    );

    // Draw center dot
    final centerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, centerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Example usage screen
class ClockScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Live Clock'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Digital Clock
            Card(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: DigitalClockWidget(),
              ),
            ),

            SizedBox(height: 30),

            // Simple Text Clock
            Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: LiveClock(
                  timeStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  dateStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Analog Clock
            Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: AnalogClock(
                  size: 250,
                  backgroundColor: Colors.white,
                  hourHandColor: Colors.black,
                  minuteHandColor: Colors.blue,
                  secondHandColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Import this at the top of your file

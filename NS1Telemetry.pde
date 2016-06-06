//
// NS1 Telemetry
// Copyright (C) 2016 David Pello
// http://ashab.space
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import processing.net.*;
import java.io.FileWriter;
// You'll need the library HTTP-Requests-for-Processing
// https://github.com/runemadsen/HTTP-Requests-for-Processing
import http.requests.*;
import java.util.Date;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.concurrent.TimeUnit;

// Upload
// The upload uses HTTP authentication, you must have a "password.txt" file 
// in the sketch working directory with at least one line containing
// user:password

String password_line;
String user;
String password;
String server_url = "http://ashab.space/tracker/upload.php";

Boolean UPLOAD_TELEMETRY = false;

// Direwolf
final String TCP_IP = "127.0.0.1";
final int    TCP_PORT = 8000;
final int    BUFFER_SIZE = 1024;

final byte   M_MESSAGE[] = { 
  0, 
  0, 0, 0, 
  'm', 
  0, 0, 0, 
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
  0, 0, 0, 0, 
  0, 0, 0, 0
};


final int FIELD_LAT = 0;
final int FIELD_LON = 1;
final int FIELD_SPD = 2;
final int FIELD_ALT = 3;
final int FIELD_VLT = 4;
final int FIELD_BAR = 5;
final int FIELD_TIN = 6;
final int FIELD_TOU = 7;
final int FIELD_DAT = 8;
final int FIELD_TIM = 9;
final int FIELD_GPS = 10;
final int FIELD_MSG = 11;

final String datafile = "ns1log.csv";

Client agw_sock;
PFont main_font;
PImage logo;
byte[] buffer = new byte[BUFFER_SIZE];
FileWriter log;
String log_entry;

Date current_date;
Date last_packet_date;
DateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
long last_packet_ago;

void setup() {
  // HTTP password
  if (UPLOAD_TELEMETRY) {
    // get password
    try {
      password_line = loadStrings("password.txt")[0];
      user = password_line.split(":")[0];
      password = password_line.split(":")[1];
    } 
    catch (Exception e) {
      println("Can't parse password");
      exit();
    }
  }


  // init screen and resources
  size(920, 120);
  background(0);
  smooth(2);
  main_font = loadFont("Ubuntu-Medium-20.vlw");
  textFont(main_font, 10);
  logo = loadImage("ashab-ns1.jpg");
  draw_interface();

  // create and open socket with direwolf
  agw_sock = new Client(this, TCP_IP, TCP_PORT);
  // send AGW "m" packet so direwolf starts sending packets to us
  agw_sock.write(M_MESSAGE);
  
  last_packet_date = new Date();
  
}

void draw() {
  // get current date and print last packet time
  current_date = new Date();
  last_packet_ago  = current_date.getTime() - last_packet_date.getTime(); 
  print_packet_time(last_packet_ago);

  
  // get packet data
  if (agw_sock.available() > 0) {
    int byte_num = agw_sock.readBytes(buffer);
    if (byte_num > 0) {
      String data = new String(buffer);
      println(data);
      // find fields
      String[] fields = split(data, "/");

      // if we have more than 11 fields, looks like a good packet
      if (fields.length > 11) {
        try {
          // clear fields that contain more than one data value
          fields[FIELD_LAT] = split(fields[FIELD_LAT], "!")[1];
          String hdg = split(fields[FIELD_LON], "O")[1];
          fields[FIELD_LON] = split(fields[FIELD_LON], "O")[0];
          String lat = split(split(fields[FIELD_GPS], "=")[1], ",")[0];
          String lon = split(split(fields[FIELD_GPS], "=")[1], ",")[1];
          String alt = split(fields[FIELD_ALT], "=")[1];
          String batt = split(fields[FIELD_VLT], "=")[1];
          String tin = split(fields[FIELD_TIN], "=")[1];
          String tout = split(fields[FIELD_TOU], "=")[1];
          String baro = split(fields[FIELD_BAR], "=")[1];

          // ok, valid packet
          last_packet_date = new Date();
          
          // draw data
          background(0);
          draw_interface();
          textSize(12);
          text("Data Valid: " + fields[FIELD_DAT] + " " + fields[FIELD_TIM], 30, 415);
          text("LAT: " + lat, 30, 40);
          text("LON: " + lon, 30, 55);
          text("ALT: " + alt + " m", 30, 70);

          text("BATT: " + batt + " V", 570, 40);
          text("TIN:  " + tin + " ºC", 570, 55);
          text("TOUT: " + tout + " ºC", 570, 70);
          text("BAR:  " + baro + " mbar", 700, 40);

          text("HDG:  " + hdg + " º", 300, 40);
          text("SPD:  " + fields[FIELD_SPD] + " kn", 300, 55);

          // append data to log file
          log = new FileWriter(datafile, true);
          log_entry = fields[FIELD_DAT] + ";" + fields[FIELD_TIM] + ";" + lat + ";" + lon + ";" +
            alt + ";" + batt + ";" + tin + ";" + tout + ";" + baro + ";" + hdg + ";" +
            fields[FIELD_SPD] + "\n";
          log.write(log_entry);
          log.close();

          // upload to server
          if (UPLOAD_TELEMETRY) {
            PostRequest post = new PostRequest(server_url);

            post.addUser(user, password);
            //post.addData("telemetry", "26-04-2016;21:15:41;43.555367N;005.667480W;20000.5;5.56;20.81;18.62;1014.0;0;0.059");
            post.addData("telemetry", log_entry);
            post.send();
            println("Reponse Content: " + post.getContent());
            println("Reponse Content-Length Header: " + post.getHeader("Content-Length"));
          }
        }
        catch (Exception e) {
          // pass
        }
      }
    }
  }
}

void draw_interface() {
  // draw interface
  stroke(255);
  fill(0);
  rect(20, 15, 250, 70);
  rect(560, 15, 250, 70);
  rect(290, 15, 250, 70);
  rect(20, 390, 250, 40);
  stroke(0);
  fill(0);
  textSize(12);
  rect(30, 20, textWidth("LOC"), -20);
  rect(570, 20, textWidth("STAT"), -20);
  rect(300, 20, textWidth("DIR"), -20);
  stroke(0);
  fill(255);
  text("LOC", 30, 20);
  text("STAT", 570, 20);
  text("DIR", 300, 20);
  image(logo, 825, 10, 80, 80);
}  

void print_packet_time(long d) {
  long diff_in_seconds;
  long diff_in_minutes;
  
  stroke(0);
  fill(0);
  textSize(12);
  rect(20, 110, textWidth("Último paquete recibido hace:               "), -20);
  stroke(0);
  fill(255);
  
  diff_in_seconds = TimeUnit.MILLISECONDS.toSeconds(d);
  if (diff_in_seconds > 59) {
    diff_in_minutes = TimeUnit.MILLISECONDS.toMinutes(d);
    text("Último paquete recibido hace: " + diff_in_minutes + "m " + diff_in_seconds % 60 + "s", 20, 105);
  } else {
    text("Último paquete recibido hace: " + diff_in_seconds + "s", 20, 105);  
  }
}
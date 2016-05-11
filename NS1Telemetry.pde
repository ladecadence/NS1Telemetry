import processing.net.*;
import java.io.FileWriter;

final String TCP_IP = "127.0.0.1";
final int    TCP_PORT = 8000;
final int    BUFFER_SIZE = 1024;

final byte   M_MESSAGE[] = { 0,
                             0,0,0,
                             'm',
                             0,0,0,
                             0,0,0,0,0,0,0,0,0,0,
                             0,0,0,0,0,0,0,0,0,0,
                             0,0,0,0,
                             0,0,0,0 };
                             

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

void setup() {
  // init screen and resources
  size(920,100);
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
  
  
  
}

void draw() {
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
         String alt = split(fields[FIELD_ALT],"=")[1];
         String batt = split(fields[FIELD_VLT],"=")[1];
         String tin = split(fields[FIELD_TIN],"=")[1];
         String tout = split(fields[FIELD_TOU],"=")[1];
         String baro = split(fields[FIELD_BAR],"=")[1];
         
         
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
         log.write(fields[FIELD_DAT] + ";" + fields[FIELD_TIM] + ";" + lat + ";" + lon + ";" +
             alt + ";" + batt + ";" + tin + ";" + tout + ";" + baro + ";" + hdg + ";" +
             fields[FIELD_SPD] + "\n");
         log.close();
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
  rect(30,20,textWidth("LOC"), -20);
  rect(570,20,textWidth("STAT"), -20);
  rect(300,20,textWidth("DIR"), -20);
  stroke(0);
  fill(255);
  text("LOC", 30, 20);
  text("STAT", 570, 20);
  text("DIR", 300, 20);
  image(logo, 825, 10, 80, 80);
}  


import processing.net.*;

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

Client agw_sock;
PFont main_font;
PImage logo;
byte[] buffer = new byte[BUFFER_SIZE];

void setup() {
  size(600,450);
  background(0);
  smooth(2);
  main_font = loadFont("Ubuntu-Medium-20.vlw");
  textFont(main_font, 20);
  logo = loadImage("ashab-ns1.jpg");
  draw_interface();
  
  // create and open socket
  agw_sock = new Client(this, TCP_IP, TCP_PORT);
  agw_sock.write(M_MESSAGE);
  
  
  
}

void draw() {
  // get data
  if (agw_sock.available() > 0) {
   int byte_num = agw_sock.readBytes(buffer);
   if (byte_num > 0) {
     String data = new String(buffer);
     println(data);
     // find fields
     String[] fields = split(data, "/");
     // clear fields
     fields[FIELD_LAT] = split(fields[FIELD_LAT], "!")[1];
     String hdg = split(fields[FIELD_LON], "O")[1];
     fields[FIELD_LON] = split(fields[FIELD_LON], "O")[0];
     
     // draw data
     background(0);
     draw_interface();
     textSize(15);
     text("Data Valid: " + fields[FIELD_DAT] + " " + fields[FIELD_TIM], 30, 415);
     text("LAT: " + fields[FIELD_LAT], 30, 70);
     text("LON: " + fields[FIELD_LON], 30, 90);
     text("ALT: " + split(fields[FIELD_ALT],"=")[1], 30, 110);
     
     text("BATT: " + split(fields[FIELD_VLT],"=")[1], 30, 250);
     text("TIN:  " + split(fields[FIELD_TIN],"=")[1], 30, 270);
     text("TOUT: " + split(fields[FIELD_TOU],"=")[1], 30, 290);
     text("BAR:  " + split(fields[FIELD_BAR],"=")[1], 30, 310);
     
     text("HDG:  " + hdg, 300, 70);
     text("SPD:  " + fields[FIELD_SPD], 300, 90);
     
   }
  }
}

void draw_interface() {
// draw interface
  stroke(255);
  fill(0);
  rect(20, 35, 250, 150);
  rect(20, 215, 250, 150);
  rect(290, 35, 250, 150);
  rect(20, 390, 250, 40);
  stroke(0);
  fill(0);
  textSize(20);
  rect(30,40,textWidth("LOC"), -20);
  rect(30,220,textWidth("STAT"), -20);
  rect(300,40,textWidth("DIR"), -20);
  stroke(0);
  fill(255);
  text("LOC", 30, 40);
  text("STAT", 30, 220);
  text("DIR", 300, 40);
  image(logo, 325, 220, 200, 200);
}  


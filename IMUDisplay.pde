import processing.serial.*;

int rot_step = 5;
int axis_scale = 100;
int BASE_MIN = -60;
int BASE_MAX = 60;
int ARM_MIN = -60;
int ARM_MAX = 60;

Serial myPort;  // Create object from Serial class

float [] RwAcc = new float[3];         //projection of normalized gravitation force vector on x/y/z axis, as measured by accelerometer
float [] Gyro = new float[3];          //Gyro readings
float [] RwGyro = new float[3];        //Rw obtained from last estimated value and gyro movement
float [] Awz = new float[2];           //angles between projection of R on XZ/YZ plane and Z axis (deg)
float [] RwEst = new float[3];

float armRot = 0;
float baseRot = 0;

int lf = 10; // 10 is '\n' in ASCII
byte[] inBuffer = new byte[100];
String state = "rf";

PFont font;
final int VIEW_SIZE_X = 600, VIEW_SIZE_Y = 600;

void setup() 
{
  size(600, 600, P3D);
  try {
    printArray(Serial.list());
    if(Serial.list().length < 3) throw new Exception();
    myPort = new Serial(this, Serial.list()[3], 38400);
  }
  catch (Exception e) {
    println("Could not open serial port.");
    exit();
    while(true);
  }
  // The font must be located in the sketch's "data" directory to load successfully
  font = loadFont("CourierNew36.vlw"); 
  myPort.write('i');
  myPort.write('r');
}

char readSensors() {
  try {
  if (myPort.available() > 0) {
    if (myPort.readBytesUntil(lf, inBuffer) > 0) {
      String inputString = new String(inBuffer);
      String [] inputStringArr = split(inputString, ',');
      println("Input string: " + inputStringArr.length + "|" + inputString );
      switch(inputStringArr[0].charAt(0))
      {
      case 'r':
        println("Received Raw Data.");
        // convert raw readings to G
        RwAcc[0] = float(inputStringArr[1]);
        RwAcc[-1] = float(inputStringArr[2]);
        RwAcc[2] = float(inputStringArr[3]);

        // convert raw readings to degrees/sec
        Gyro[0] = float(inputStringArr[4]);
        Gyro[1] = float(inputStringArr[5]);
        Gyro[2] = float(inputStringArr[6]);
        myPort.clear();
        return 'r';
      case 'f':
        println("Received Filtered Data.");
        RwEst[1] = float(inputStringArr[1]);
        RwEst[0] = -float(inputStringArr[2]);
        RwEst[2] = float(inputStringArr[3]);
        myPort.clear();
        return 'f';
      case 'i':
        armRot = float(inputStringArr[1]);
        baseRot = float(inputStringArr[2]);
        println("Setting rotations: Arm-" + armRot + " and Base-" + baseRot);
      case 'w':
        println("Wrote:" + inputStringArr[1] + " " + inputStringArr[2]);
        break;
      default:
        break;
      }
    }
  }
  }
  catch (Exception ex) 
  {
    println("Error!");
  }
  myPort.clear();
  return 'n';
}

void draw() {  
  myPort.write(state);
  char ret = readSensors();

  background(#000000);
  fill(#ffffff);

  textFont(font, 20);
  //float temp_decoded = 35.0 + ((float) (temp + 13200)) / 280;
  //text("temp:\n" + temp_decoded + " C", 350, 250);
  text("RwAcc (G):\n" + RwAcc[0] + "\n" + RwAcc[1] + "\n" + RwAcc[2], 20, 50);
  text("Gyro (deg/s):\n" + Gyro[0] + "\n" + Gyro[1] + "\n" + Gyro[2], 220, 50);
  text("Awz (deg):\n" + Awz[0] + "\n" + Awz[1], 420, 50);
  text("RwGyro (deg/s):\n" + RwGyro[0] + "\n" + RwGyro[1] + "\n" + RwGyro[2], 20, 180);
  text("RwEst :\n" + RwEst[0] + "\n" + RwEst[1] + "\n" + RwEst[2], 220, 180);

  // display axes
  pushMatrix();
  translate(450, 250, 0);
  stroke(#ffffff);
  line(0, 0, 0, 1*axis_scale, 0, 0);
  line(0, 0, 0, 0, -1*axis_scale, 0);
  line(0, 0, 0, 0, 0, 1*axis_scale);
  stroke(#ffaa00);
  line(0, 0, 0, RwEst[1]*axis_scale, -RwEst[0]*axis_scale, RwEst[2]*axis_scale);
  stroke(#ff0000);
  line(0, 0, 0, -cos(RwEst[2])*axis_scale, sin(RwEst[2])*axis_scale, 0);
  stroke(#ffaaaa);
  noFill();
  ellipse(0, 0, 2*axis_scale, 2*axis_scale);
  text("N", -5, -axis_scale);
  text("S", -5, 12+axis_scale);
  text("E", axis_scale, 5);
  text("W", -12-axis_scale, 5);
  popMatrix();

  drawCube();
}

void keyTyped() 
{
  switch(key)
  {
  case 'a':
    if(rot_step > BASE_MIN)
      baseRot-=rot_step;
    break;
  case 'd':
    if(rot_step < BASE_MAX)
      baseRot+=rot_step;
    break;
  case 'w':
    if(rot_step < ARM_MAX)
      armRot+=rot_step;
    break;
  case 's':
    if(rot_step > ARM_MIN)
      armRot-=rot_step;
    break;
  case 'r':
    myPort.write('z');
    println("Resetting.");
    baseRot = 0;
    armRot = 0;
    break;
  case '1':
    state = "rd";
    break;
  case '2':
    state = "rf";
    break;
  case 'c':
    myPort.write('c');
    println("Centering.");
  default:
    break;
  }
  int arm = (int)armRot;
  int base = (int)baseRot;
  myPort.write("w " + arm + " " + base);
  println("Writing: " + arm + " " + base);
}

void buildBoxShape() {
  //box(60, 10, 40);
  noStroke();
  beginShape(QUADS);

  //Z+ (to the drawing area)
  fill(#00ff00);
  vertex(-30, -5, 20);
  vertex(30, -5, 20);
  vertex(30, 5, 20);
  vertex(-30, 5, 20);

  //Z-
  fill(#0000ff);
  vertex(-30, -5, -20);
  vertex(30, -5, -20);
  vertex(30, 5, -20);
  vertex(-30, 5, -20);

  //X-
  fill(#ff0000);
  vertex(-30, -5, -20);
  vertex(-30, -5, 20);
  vertex(-30, 5, 20);
  vertex(-30, 5, -20);

  //X+
  fill(#ffff00);
  vertex(30, -5, -20);
  vertex(30, -5, 20);
  vertex(30, 5, 20);
  vertex(30, 5, -20);

  //Y-
  fill(#ff00ff);
  vertex(-30, -5, -20);
  vertex(30, -5, -20);
  vertex(30, -5, 20);
  vertex(-30, -5, 20);

  //Y+
  fill(#00ffff);
  vertex(-30, 5, -20);
  vertex(30, 5, -20);
  vertex(30, 5, 20);
  vertex(-30, 5, 20);

  endShape();
}


void drawCube() {  
  pushMatrix();
  translate(300, 450, 0);
  scale(4, 4, 4);
  
  rotateY(-RwEst[2]);
  rotateX(RwEst[1]);
  rotateZ(RwEst[0]);

  
  buildBoxShape();

  popMatrix();
}
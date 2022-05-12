PImage img;
import g4p_controls.*; 

//delay for car spawns 
int carSpawnDelay = 70; 
int carSpawnTimer = carSpawnDelay;

//booleans for allowing editing of the road shape and pre-simulation settings
boolean adjusting = true;
boolean makingRoad = false;

//objects and object arrayLists
Lane roadMid;
Car car;
ArrayList<Lane> laneMids = new ArrayList<Lane>(); 
ArrayList<Lane> edgeLaneList = new ArrayList<Lane>();
ArrayList<Car> allCars = new ArrayList<Car>();

//initial slider values
int numLanes = 1;
int maxAnger = 5;
float speedLim = 80;

//variables for lane changing behaviour
int passingCooldown = 5;
float passingCooldownAngerModifier = 2;

//other global variables
float roadWidth = 25;
float extendNum = 50;

//Setup initial settings
void setup(){ 
  imageMode(CENTER);
  size(1000,1000);
  background(10,80,40);
  createGUI();
  img = loadImage("car.png");
  
  //lane that represents the middle of the road is copied and placed in the arrayList of lanes
  roadMid = new Lane();
  Lane m = extend(roadMid); 
  laneMids.add(m);
}

//In every frame, the background is reset, the road is drawn, car's positions are updated, new cars are spawned and offscreen cars are removed
void draw(){  
  background(10,80,40);
  fill(133, 133, 133);
  stroke(133, 133, 133);
  rect(0,0,width,150);
  drawRoad();
  updateCars();
  spawnCars();
  removeCars();
}

//In this function, the road along with the dotted lines are drawn
void drawRoad(){
  stroke(133, 133, 133);
  strokeWeight(roadWidth+2);
  noFill();
  strokeCap(SQUARE);
  for(int k = 0; k < laneMids.size(); k++){
    Lane midLane = laneMids.get(k);
    
    //Processing's beginShape function is used, linking points together in a curve 
    beginShape();
    
    for(int i = 0; i < midLane.points.size(); i++){
      curveVertex(midLane.points.get(i).x, midLane.points.get(i).y);
    }
    
    endShape();
  }
  stroke(255, 255, 255);
  strokeWeight(3);
  
  //we alternate between drawing white and transparent curves, creating dotted lines
  for(int z = 0; z < edgeLaneList.size(); z++){
    Lane currLane = edgeLaneList.get(z);
    for(int x = 0; x < currLane.points.size(); x++){
      try{
        beginShape();
        for(int i = 0; i < 4; i++){
          curveVertex(currLane.points.get(x+i).x, currLane.points.get(x+i).y);
        }
        endShape();
        }
      catch(Exception e){}
    x += 1;
    }
  }
}

//If the user is making the road and the mouse is pressed, then a new point is added to the middle lane, and all of the other lanes are shifted accordingly
void mousePressed(){
  if(makingRoad){
    roadMid.points.add(roadMid.points.size()-2,new PVector(mouseX, mouseY));
    ArrayList<Lane> newMid = new ArrayList<Lane>();
    newMid.add(extend(roadMid));
    laneMids = newMid;
    addLanes(numberLanes.getValueI(), true);
  }
}

//whenever the user presses a key while adjusting the road, the program will alternate between making or not making the road
void keyPressed(){
  if(adjusting == true)
    makingRoad = !makingRoad;
    
  if(makingRoad && adjusting == true)
    makingRoadText.setText("Making Road");
  
  else
    makingRoadText.setText("Not Making Road");
}

//This function generates 2 new lanes equisdant to the base curve (one above and one below)
Lane[] genLane(Lane startLane, float p, float roadWidthMod){
  Lane newLane1 = new Lane("empty");
  Lane newLane2 = new Lane("empty");
  
  for(int i = 0; i < startLane.points.size(); i++) {  
    float x = startLane.points.get(i).x;
    float y = startLane.points.get(i).y;
    float tx = 0;
    float ty = 0;
    float t = 0;
    int k = 0;
    boolean noErrorFound = false;
    while(noErrorFound == false){ //tries to get the tangent vector of the point, if it exceeds the array size then it falls into the catch
      try{
        tx = curveTangent(startLane.points.get(k+i).x, startLane.points.get(k+i+1).x, startLane.points.get(k+i+2).x, startLane.points.get(k+i+3).x, t);
        ty = curveTangent(startLane.points.get(k+i).y, startLane.points.get(k+i+1).y, startLane.points.get(k+i+2).y, startLane.points.get(k+i+3).y, t);
        noErrorFound = true;
      }
      
      catch(Exception E){ //the catch goes back a section in the curve to stay within the array size
        k -= 1;
        t += 1 / 3;
      }
    }
    
    //vector calculations to get the new point to be considered in the new lane
    float tMag1 = sqrt(tx*tx + ty*ty);
    float tMag2 = -1 * tMag1;
    float tx1 = tx * roadWidth * (p + 1) / tMag1 * roadWidthMod;
    float ty1 = ty * roadWidth * (p + 1) / tMag1 * roadWidthMod;
    float tx2 = tx * roadWidth * (p + 1) / tMag2 * roadWidthMod;
    float ty2 = ty * roadWidth * (p + 1) / tMag2 * roadWidthMod;
    
    newLane1.points.add(new PVector(x-ty1, y+tx1));
    newLane2.points.add(new PVector(x-ty2, y+tx2));
  }
  
  Lane[] lanes = {newLane1, newLane2};
  return lanes;
}

//A parallel curve can't be created given only 4 or 5 points, so this function converts a curve into a list of hundreds of points to create a precise parallel curve
Lane extend(Lane l){
  float pointCutoff = 10;
  Lane newLane = new Lane("empty"); //a lane with an empty arrayList is initialized
  
  for(int z = 0; z < l.points.size() - 3; z++){
    for(float t = 0; t < 1 + 1/extendNum - 0.000001; t += 1/extendNum){
      float x = round(curvePoint(l.points.get(0+z).x, l.points.get(1+z).x, l.points.get(2+z).x, l.points.get(3+z).x, t));
      float y = round(curvePoint(l.points.get(0+z).y, l.points.get(1+z).y, l.points.get(2+z).y, l.points.get(3+z).y, t));
      
      //try-catch is used here to prevent exceeding an arrayList's range
      try{ 
        PVector prevPoint = newLane.points.get(newLane.points.size()-1);
        if(sqrt(pow((x - prevPoint.x), 2) + pow((y - prevPoint.y), 2)) >= pointCutoff){
           newLane.points.add(new PVector(x, y));
      
          if(z == 0 && t == 0 || z == l.points.size() - 4 && t >= 1) //controls points will be added twice
            newLane.points.add(new PVector(x, y));
        }
      }
      catch(Exception E){
        newLane.points.add(new PVector(x, y));
      
        if(z == 0 && t == 0 || z == l.points.size() - 4 && t >= 1)
          newLane.points.add(new PVector(x, y));
      }
    }
  }
  return newLane;
}

//This function spawns new cars every several frames
void spawnCars(){
  boolean spawnCar = true;
  for(int i=0;i<allCars.size();i++){
    if(allCars.get(i).tt<1){
      spawnCar = false;
    }
  }
  if(spawnCar){
    carSpawnTimer++;
  
    if(carSpawnTimer >= carSpawnDelay && adjusting == false){
      carSpawnTimer = 0;
      allCars.add(new Car());
    }
  }
  
}

//This function generates additional road lanes off of a base lane and re-adjusts them based on whether the number of lanes is even or odd
void addLanes(int numLanes, boolean autoRun){
  
  if(adjusting == true || autoRun == true){
    
    if(autoRun == false)
      makingRoad = false;
      
    Lane startLane = extend(roadMid);
    ArrayList<Lane> newRoadLines = new ArrayList<Lane>();
    ArrayList<Lane> newMids = new ArrayList<Lane>();
    
    //generation of lanes based on even number of lanes
    if(numLanes % 2 == 0){
      newRoadLines.add(startLane);
      
      for(int p = 0; p < numLanes / 2; p++){
        Lane[] laneList;
        
        if(p == 0)
          laneList = genLane(startLane, p, 0.5);//The genLane function is used to get an array-list of points from the base road
          
        else{
          laneList = genLane(startLane, p, 0.75);
          Lane roadLine1 = genLane(startLane, p, 0.5)[0];
          newRoadLines.add(roadLine1);
          Lane roadLine2 = genLane(startLane, p, 0.5)[1];
          newRoadLines.add(roadLine2);
        }
        
        newMids.add(0, laneList[0]);
        newMids.add(laneList[1]);
      }
    }
    
    //generation of lanes based on an odd number of lanes
    else if(numLanes % 2 == 1){
      for(int p = 0; p < (numLanes - 1) / 2; p++){      
        Lane[] laneList = genLane(startLane, p, 1);
        newMids.add(0, laneList[0]);
        newMids.add(laneList[1]);
        
        if(numLanes > 1){
          if(p != (numLanes - 1) / 2 - 1){
            Lane roadLine1 = genLane(laneList[0], p, 0.5)[0];
            newRoadLines.add(roadLine1);
            Lane roadLine2 = genLane(laneList[1], p, 0.5)[1];
            newRoadLines.add(roadLine2);
          }
        }   
      }   
      
      newMids.add((numLanes - 1) / 2, startLane);
      
      if(numLanes > 1 && numLanes % 2 == 1){
        Lane roadMidLine1 = genLane(startLane, 0, 0.5)[0];
        Lane roadMidLine2 = genLane(startLane, 0, 0.5)[1];
        newRoadLines.add(roadMidLine1);
        newRoadLines.add(roadMidLine2);
      }
    }
    
    else
      newMids = laneMids;
    
    laneMids = newMids;
    edgeLaneList = newRoadLines; 
  }
}

//calculate the angle by which the car png is rotated 
float getAngle(float x,float y){ 
  float r = 0;
  if(x == 0 ) {
  
    if(y < 0) 
      r = -PI/2.0;
    
    else 
      r = PI/2;
  }
    
  if(y == 0){ 
  
    if(x < 0) 
      r = PI;
    
    else 
      r = 0;
  }
  
  if(x > 0){
  
    if(y > 0) 
      r = atan(y / x);
    
    else
      r = atan(y / x);
  }
      
  if(x < 0){
  
    if(y > 0) 
      r = PI + atan(y / x);
    
    else
      r = PI + atan(y / x);
  }
  return(r);
}

//function to remove cars from the arrayList when they drive off the screen
void removeCars(){
  for(int i = allCars.size()-1; i >= 0; i--){
    Car car = allCars.get(i);
    if(car.offScreen == true)
      allCars.remove(i);
  }
}

//function that updates the cars positions, lanes, detect crashing, and draws the car
void updateCars(){
  for(int i = allCars.size()-1; i >= 0; i--){ //iterating from the end of the arrayList prevents errors caused by removing cars from the arrayList
    Car currCar = allCars.get(i);
    currCar.passCooldown --;
    
    if(currCar.offScreen == false)
      currCar.display();
      
    if(!currCar.crashed){
      currCar.updatePosition();   
      currCar.changeLane();
      
      //ensure a car's lane number is within the possible lane numbers
      if(currCar.laneNum < 0){ 
        currCar.laneNum = 0;
      }
      
      if(currCar.laneNum >= laneMids.size()) {
        currCar.laneNum = laneMids.size()-1;
      }
      
      currCar.checkCrash();
    }
  }
}

//reset button
void reset(){
  roadEditingButton.setText("Stop Editing Road");
  makingRoadText.setText("Not Making Road");
  numberLanes.setValue(1);
  speedSlider.setValue(60);
  angry.setValue(5);
  spawn.setValue(30);
  
  laneMids = new ArrayList<Lane>();
  allCars = new ArrayList<Car>();
  edgeLaneList = new ArrayList<Lane>();
  
  adjusting = true;
  numLanes = 1;
  roadMid = new Lane();
  Lane m = extend(roadMid);
  laneMids.add(m);
}

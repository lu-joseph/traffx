public class Car {
  float t;//how far along current curve the car is, float between 0 and 1
  float tt;//how far along the entire lane the car is
  int z;//an entire lane is split into multiple curves, z is the curve number the car is on
  
  int index; //the car's index in the allCars arrayList

  float a; //acceleration
  float speed; //in km/h
  float tIncr; //the actual value that t is incremented by
  float comfSpeed; //the preferred speed the car will drive at, in km/h

  float anger;//a car's anger value affects its aggressive behaviour
  
  boolean crashed;
  boolean offScreen;
  
  int laneNum;
  
  boolean following;
  
  float passCooldown;
  float passCooldownReset;
  color green = color(0,255,0),blue = color(0,0,255),black = color(0),yellow = color(255,255,0),
        grey = color(50,50,50),orange = color(255,165,0),purple = color(255,0,255),cyan = color(0,255,255);
  color[] possibleColors = {green,blue,black,yellow,grey,orange,purple,cyan};
  color carColor;

  Car() {
    this.anger = random(0.7, 0.7+0.1*maxAnger);
    this.comfSpeed = speedLim*anger;
    this.speed = speedLim*0.8; //a car's initial speed is set to between 50% to 100% of of the speed limit
    
    //initial values
    this.t = 0;
    this.a = 0;
    this.tIncr = 0;
    this.z = 0;
    this.carColor = possibleColors[int(random(possibleColors.length))];
    
    this.crashed = false;
    this.offScreen = false;
    
    this.passCooldown = passingCooldown + (10 - this.anger) * 2;
    this.passCooldownReset = passingCooldown + (10 - this.anger) * passingCooldownAngerModifier;
    
    //sets a random lane for the car to start in
    this.laneNum = round(random(0, laneMids.size() - 1));
  }
  
  //This function updates the position of a car by moving it along the curve at a distance parallel to the speed
  void updatePosition() {
    if (this.t < 1) {
      determineAcceleration();
      this.speed += this.a;
      this.tIncr = this.speed/500; //adjusts the km/h values to actual t increments

      if (this.tIncr < 0.001) //sets the increment to 0 if the speed is minimal
        this.tIncr = 0;

      if (this.speed < 0.001*500) //same thing for speed in km/h
        this.speed = 0;
        
      this.t += tIncr; //the t and tt values are incremented
      this.tt += tIncr;
    } 
    else {
      this.t = 0; //if the t value for the section of the curve has reached 1, it is reset to 0
      this.z += 1;//car moves on to the next section of the curve
      
      //detects if the car has driven off the last section of the curve, and therefore off the screen
      if (this.z + 3 >= laneMids.get(laneNum).points.size()-1) {
        offScreen = true;
      }
    }
  }

  //method that checks whether the car has crashed
  void checkCrash() {
    for (int i = allCars.size()-1; i >= 0; i--) {
      for (int j = allCars.size()-1; j >= 0; j--) {
        PVector carOne = allCars.get(i).getPosition();
        PVector carTwo = allCars.get(j).getPosition();
        
        //if the x and y distances between two cars are less than 10, then the cars have crashed
        if (abs(carOne.x-carTwo.x) < 10 && abs(carOne.y-carTwo.y) < 10 && i != j) {
          allCars.get(i).crashed = true;
          allCars.get(i).speed = 0;
          allCars.get(j).crashed = true;
          allCars.get(j).speed = 0;
        }
      }
    }
  }
  
  //this method gets the x,y position of the car on the screen, using curvePoint()
  PVector getPosition() {
    Lane midLane = laneMids.get(this.laneNum); 
    float x = curvePoint(midLane.points.get(0+this.z).x, midLane.points.get(1+this.z).x, midLane.points.get(2+this.z).x, midLane.points.get(3+this.z).x, this.t);
    float y = curvePoint(midLane.points.get(0+this.z).y, midLane.points.get(1+this.z).y, midLane.points.get(2+this.z).y, midLane.points.get(3+this.z).y, this.t);
    return new PVector(x, y);
  }

  //this method returns a simple array of the x and y components of the curveTangent vector
  float[] getslopeValues() {
    Lane midLane = laneMids.get(this.laneNum);
    float xSlope = curveTangent(midLane.points.get(0+this.z).x, midLane.points.get(1+this.z).x, midLane.points.get(2+this.z).x, midLane.points.get(3+this.z).x, this.t);
    float ySlope = curveTangent(midLane.points.get(0+this.z).y, midLane.points.get(1+this.z).y, midLane.points.get(2+this.z).y, midLane.points.get(3+this.z).y, this.t);
    return new float[] {xSlope, ySlope};
  }
  
  //this method draws the car on the screen
  void display() {
    pushMatrix();
    
    //position and angle are determined
    PVector position = getPosition();
    float[] slope = getslopeValues();
    translate(position.x, position.y); //Moving the car into position
    float r = getAngle(slope[0], slope[1]); //Getting the angle the car is facing
    rotate(r);
    
    //colour is changed if the car has crashed
    if (this.crashed)
      tint(255,0,0);
    else
      tint(this.carColor);
    
    image(img, 0, 0, 25, 25); // drawing the car
    noTint(); //resetting tint
    popMatrix();
  }
  
  //acceleration/decelleration is determined based on detecting cars ahead
  void determineAcceleration() {
    boolean slowDown = checkCar(0); //determines whether a car is ahead, and the current car should slow down
    Car nextCar = detectCar(0);
    
    if (slowDown) {
      if(nextCar.speed<40){
        this.a = -100;
      } else{
        this.a = (nextCar.speed - this.speed)*0.3;
      }
      //minimum and maximum decelleration restrictions
      if (this.a>-0.001)
        this.a = 0;

      else if (this.a<-100)
        this.a = -100;
      
    } 
    else
      this.a = (this.comfSpeed - this.speed)/100; //if not following another car, the current car will accellerate to its comfortable speed
  }

  //this method allows a car to change lanes if it detects a car in front of it and its "passing cooldown" has passed
  void changeLane() {
    ArrayList<Integer> busyLanes = new ArrayList<Integer>();
    
    if (checkCar(0) && this.passCooldown < 0) {
      for(int j=0;j<allCars.size();j++){
        if(abs(allCars.get(j).laneNum-this.laneNum)==1){
          if(abs(allCars.get(j).tt-this.tt)<5 - 0.25 * this.anger){
            busyLanes.add(allCars.get(j).laneNum - this.laneNum); //
          } 
        }
      }
      
      boolean leftBusy = false;
      boolean rightBusy = false;
      
      for(int i=0;i<busyLanes.size();i++){
        if(busyLanes.get(i)==-1){
          leftBusy = true;
        } else if(busyLanes.get(i)==1){
          rightBusy = true;
        }
      }
      
      if(busyLanes.size()==0){
        //change to either lane
        if(random(1)>0.5)
          this.laneNum++; //changes the car's lane number into that adjacent lane
        else
          this.laneNum--;
          
        this.passCooldown = this.passCooldownReset;
      }
      else if(leftBusy && !rightBusy){
        this.laneNum++;
        this.passCooldown = this.passCooldownReset;
      } 
      else if(!leftBusy && rightBusy){
        this.laneNum--;
        this.passCooldown = this.passCooldownReset;
      }
    }  
  }
    
  //this method detects the closest car in front
  //the k value is added to the lane number (0 is same lane, 1 is one lane beside)
  Car detectCar(int k) {
    float minDist = 1000000;
    Car nextCar = this;
    
    //finds the car with the minimum distance away, assigns that car to nextCar
    for (int i=0; i<allCars.size(); i++) {
      if (i!=this.index) { //ensures the car does not check itself
        Car target = allCars.get(i);
        if (target.laneNum==this.laneNum+k && target.tt>this.tt) {
          if (abs(target.tt-this.tt)<minDist)
            nextCar = target;
            
          minDist = abs(target.tt-this.tt);
        }
      }
    }
    return nextCar;
  }
  
  //this method checks to see if there is a car closely in front
  //the k value is added to the lane number (0 is same lane, 1 is one lane beside)
  boolean checkCar(int k) {
    boolean carInFront = false;
    this.following = false;
     if(this.laneNum+k >= 0 && this.laneNum+k < laneMids.size()){
      for (int i=0; i<allCars.size(); i++) {
        if (i!=this.index) {
          Car target = allCars.get(i);

          //target car can set carInFront to true if it detects a car within a tiny distance or a large distance proportional to the speed
          if (target.tt-this.tt<4-anger*0.1) { 
            if (target.laneNum==this.laneNum+k && target.tt>this.tt) {
              carInFront = true;
              this.following = true;
            } 
          } else {
            if (target.laneNum==this.laneNum+k && target.tt>this.tt && (target.tt-this.tt)<this.tIncr*45) {
              carInFront = true;
              this.following = true;
            }
          }
        }
      }
    } 
    return carInFront;
  }
}

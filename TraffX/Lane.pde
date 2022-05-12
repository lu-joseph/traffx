class Lane{
  ArrayList<PVector> points; //arrayList of points the curve goes through
  int laneNum;//the lane number 
  
  Lane(){
    this.points = new ArrayList<PVector>();
    this.points.add(new PVector(-50,height/2));
    this.points.add(new PVector(-50,height/2));
    this.points.add(new PVector(width+50,height/2));
    this.points.add(new PVector(width+50,height/2));
  }
  
  Lane(String s){ //an optional constructor that sets an initial empty arrayList for points
    this.points = new ArrayList<PVector>();
  }
  
  
}

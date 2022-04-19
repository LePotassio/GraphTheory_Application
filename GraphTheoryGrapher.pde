// Created By Eric Furukawa, 2020

import java.util.Collections;

ArrayList<Vertex> vList = new ArrayList<Vertex>();
ArrayList<Edge> eList = new ArrayList<Edge>();
String[] sList = new String[4];
boolean deleteMode = false;//Mode could have been an ENUM
boolean colorMode = false;
Vertex held = null;
//Edge creating = null;
CreationEdge creating;

int vDiam = 20;

int prevMouseX;
int prevMouseY;

boolean afterEdgeDeletion;

boolean controls;
boolean componentsDisp;

float heldOffsetX;
float heldOffsetY;
boolean initialPressed;

//public enum mode{ADD, DELETE, MOVE}

void setup() {
  size(500, 500);
  sList[0] = "Vertices = 0";
  sList[1] = "Mode = Edit";
  sList[2] = "Edges = 0";
  sList[3] = "";
  fill(color(5));
  afterEdgeDeletion = false;
  controls = true;
  componentsDisp = true;
  initialPressed = true;
}

void restart() {
  
}

void draw() {
  //println("FrameRate: " + frameRate);
  background(255);
  drawAll();
  updateHeld();
  updateCreating();
}

void mouseClicked() {
  Vertex pressedV = checkOverVertex();
  if(colorMode && pressedV != null) {
    int col = color(5);
    pressedV.colorIndex++;
    if (pressedV.colorIndex == 5) {
      pressedV.colorIndex = -1;
    }
    switch (pressedV.colorIndex) {
      case 0:
      col = color(5);
      break;
      case 1:
      col = color(0, 51, 204);
      break;
      case 2:
      col = color(153, 0, 0);
      break;
      case 3:
      col = color(0, 153, 51);
      break;
      case 4:
      col = color(153, 0, 255);
      break;
      case -1:
      col = color(255, 153, 255);
      break;
    }
    pressedV.colorVal = col;
    pressedV.image.setFill(col);
  }
  else if(!deleteMode && pressedV == null && creating == null) {
    //create a vertex with new shape and add to list
    addNewVertex();
    //print("New Vertex Added\n");
  }
  else if(deleteMode && pressedV != null && creating == null && afterEdgeDeletion == false) {
    pressedV.deleteAllVEdges();
    vList.remove(pressedV);
    pressedV = null;
    updateStrings();
  }
  afterEdgeDeletion = false;
}

//Need a way to determine drag vs click for vertex move vs edge creation
void mousePressed() {
  if (creating == null) {
    prevMouseX = mouseX;
    prevMouseY = mouseY;
    if (!deleteMode && !colorMode) {
      held = checkOverVertex();
      if (held != null && initialPressed) {
        heldOffsetX = mouseX - held.image.getParams()[0];
        heldOffsetY = mouseY - held.image.getParams()[1];
        initialPressed = false;
        //println(heldOffsetX);
      }
    }
  }
}

void mouseReleased() {
  if (!deleteMode) {
    held = null;
    initialPressed = true;
  }
  if(!colorMode) {
    Vertex pressedV = checkOverVertex();
    if (creating == null) { 
      if(pressedV != null && mouseX == prevMouseX && mouseY == prevMouseY && !deleteMode) {
        //Edge creation 
        createEdgePt1(pressedV);
      }
    }
    else if(pressedV != null) {//could check null outside...
      createEdgePt2(pressedV);
    }
  }
}

void keyPressed() {
  if (key == CODED && keyCode == CONTROL && held == null && !colorMode) {
    deleteMode = true;
    updateStrings();
  }
  
  if (key == DELETE && creating != null) {
    creating = null;
  }
  
  if (key == 'm') {
    if (controls) {
      controls = false;
    }
    else {
      controls = true;
    }
  }
  
  if (key == 'n') {
    if (componentsDisp) {
      componentsDisp = false;
    }
    else {
      componentsDisp = true;
    }
  }
  
  if (key == 'c' && held == null && creating == null) {
    colorMode = true;
    updateStrings();
  }
}

void keyReleased() {
  if (key == CODED && keyCode == CONTROL && held == null && !colorMode) {//Other modes added just in case shenanegans
    deleteMode = false;
    updateStrings();
  }
  
  if (key == 'c' && held == null && creating == null && !deleteMode) {
    colorMode = false;
    updateStrings();
  }
}

public class Vertex {
  int vNumber;
  PShape image;
  ArrayList<Edge> cEdges = new ArrayList<Edge>();
  int colorIndex;
  int colorVal;
  
  Vertex(int color_1) {
    vNumber = getAvaliableVNumber();
    colorVal = color(5);
    image = createShape(ELLIPSE, mouseX, mouseY, vDiam, vDiam);
    switch(color_1) {
      case 0:
      image.setFill(color(5));
      break;
    }
  }
  
  void readjustVertexEdges() {
    for(Edge e : cEdges) {
      if(e instanceof Loop) {
          noFill();
          e.image = createShape(ELLIPSE, e.start.image.getParams()[0] - 15, e.start.image.getParams()[1] - 15, 40, 40);
          fill(color(5));
        }
      else if(e.start.vNumber == this.vNumber) {
          e.image  = createShape(LINE, held.image.getParams()[0], held.image.getParams()[1], e.end.image.getParams()[0], e.end.image.getParams()[1]);
      }
      else {
        e.image  = createShape(LINE, held.image.getParams()[0], held.image.getParams()[1], e.start.image.getParams()[0], e.start.image.getParams()[1]);
      }
    }
  }
  void deleteAllVEdges() {
    for (Edge e : cEdges) {
      if(e.start == this) {
        e.end.cEdges.remove(e);
      }
      else {
        e.start.cEdges.remove(e);
      }
      eList.remove(e);
      e = null;
    }
    /*for (Edge e : eList) {
      if(e.start.vNumber == this.vNumber || e.end.vNumber == this.vNumber) {
        e = null;
      }
    }*/
  }
  
  int getDegree() {
    int degs = 0;
    for (Edge e : cEdges)
      degs += e.multiplicity;
    return degs;
  }
  
  ArrayList<Vertex> getAdjacentVerts() {
    ArrayList<Vertex> adj = new ArrayList<Vertex>();
    for (Edge e : cEdges) {
      if (e.start == this) {
        adj.add(e.end);
      } else {
        adj.add(e.start);//note this allows for adjacency to self
      }
    }
    return adj;
  }
}

public class Edge {
  PShape image;
  Vertex start;
  Vertex end;
  int multiplicity;
  
  Edge(int color_1, float x1, float y1, float x2, float y2) {
    multiplicity = 1;
    image = createShape(LINE, x1, y1, x2, y2);
    switch(color_1) {
      case 0:
      image.setFill(color(5));
      break;
    }
  }
  
  Edge() {
  }
  
  /*
  void setMultiplicity(int newMult) {
    multiplicity = newMult;
  }*/
}

public class Loop extends Edge {
  
  Loop(float x1, float y1) {
    multiplicity = 1;
    noFill();
    image = createShape(ELLIPSE, x1 - 15, y1 - 15, 40, 40);
    fill(color(5));
  }
  
  /*
  void setMultiplicity(int newMult) {
    multiplicity = newMult;
  }*/
}

public class CreationEdge {//Potentially repetitive, but keeping in just in case
  Edge tempEdge;
  Vertex start;
  Vertex end;
  
  void createTempEdge() {
    tempEdge = new Edge(0, start.image.getParams()[0], start.image.getParams()[1], mouseX, mouseY);
  }
}

void addNewVertex() {
  Vertex newV = new Vertex(0);
  vList.add(newV);
  updateStrings();
}

void drawAll() {
  for(Vertex v : vList) {
    shape(v.image);
    text(v.vNumber + "(Deg:" + v.getDegree() + ")", v.image.getParams()[0] + 7, v.image.getParams()[1] + 20);
  }
  for(Edge e : eList) {
    shape(e.image);
    if (e.multiplicity > 1) {
      if (e instanceof Loop) {
        text(e.multiplicity, e.start.image.getParams()[0] - 28, e.start.image.getParams()[1] - 28);
      }
      else {
        text(e.multiplicity, (e.start.image.getParams()[0] + e.end.image.getParams()[0]) / 2, (e.start.image.getParams()[1] + e.end.image.getParams()[1]) / 2);
      }
    }
  }
  text(sList[0], 10, 10);
  text(sList[1], 10, 20);
  text(sList[2], 100, 10);
  if (componentsDisp) {
    text(sList[3], 200, 10);
  }
  if(controls) {
    text("Controls:\n\nToggle Controls:m\nAdd Vertex:Click Empty\nMove Vertex:Drag Vertex\nStart edge:Click Vertex (again to end edge)\nDeletion Mode:Hold CTRL:\nDelete Vertex:Click on Vertex in DeletionMode\nRemoveEdge:Click on Vertex in EditMode then click Vertex in DeletionMode\nCancel edge:Delete Key while creating Edge\nCycle Vertex Color:Hold c and click vertex\nToggle Components:n\n", 0, 330);
  }
  if(creating != null)
    shape(creating.tempEdge.image);
}

void updateStrings() {
  sList[0] = "Vertices = " + vList.size();
  sList[2] = "Edges = " + getEdgeCount();
  if (deleteMode) {
    sList[1] = "Mode = " + "Delete";
  }
  else if(colorMode) {
    sList[1] = "Mode = " + "Color";
  }
  else {
    sList[1] = "Mode = " + "Edit";
  }
  sList[3] = getComponents();
}

Vertex checkOverVertex() {
  // For all vertices, check if mouse x and y are in circle
  // If it is, set held to it
  for (Vertex v : vList) {
    float x = v.image.getParams()[0];
    float y = v.image.getParams()[1];
    float disX = x - mouseX;
    float disY = y - mouseY;
    if (sqrt(sq(disX) + sq(disY)) < vDiam/2) {
      return v;
    }
  }
  return null;
}

Edge checkOverEdge() {
  // For all vertices, check if mouse x and y are in line zone
  for (Edge e : eList) {
    float x = e.image.getParams()[0];
    float y = e.image.getParams()[1];
    float disX = x - mouseX;
    float disY = y - mouseY;
    if (sqrt(sq(disX) + sq(disY)) < vDiam/2) {
      return e;
    }
  }
  return null;
}

void updateHeld() {
  if (held != null) {
    held.image = createShape(ELLIPSE, mouseX - heldOffsetX , mouseY - heldOffsetY, vDiam, vDiam);
    held.image.setFill(held.colorVal);
    held.readjustVertexEdges();
  }
}

void createEdgePt1(Vertex start) {
  creating = new CreationEdge();
  creating.start = start;
  creating.createTempEdge();
}

void createEdgePt2(Vertex end) {
  //Search to see if edge already in list
  Edge preExistingE = getExistingEdge(creating.start, end);
  
  if(preExistingE != null) {
    if(deleteMode) {
      if(preExistingE.multiplicity  == 1) {
        eList.remove(preExistingE);
        preExistingE.start.cEdges.remove(preExistingE);
        preExistingE.end.cEdges.remove(preExistingE);
      }
      else {
        preExistingE.multiplicity--;
      }
      afterEdgeDeletion = true;
    }
    else {
      preExistingE.multiplicity++;
    }
  }
  else if(deleteMode) {
    afterEdgeDeletion = true;
  }
  else {
    Edge newE;
    if(creating.start.vNumber != end.vNumber) {
      newE = new Edge(0, creating.start.image.getParams()[0], creating.start.image.getParams()[1], end.image.getParams()[0], end.image.getParams()[1]);
      //println("Creating Edge");
    }
    else {
      newE = new Loop(creating.start.image.getParams()[0], creating.start.image.getParams()[1]);
      //println("Creating Loop");
    }
    creating.end = end;
    creating.start.cEdges.add(newE);
    creating.end.cEdges.add(newE);
    newE.start = creating.start;
    newE.end = creating.end;
    
    eList.add(newE);
  }
  updateStrings();
  creating = null;
}

void updateCreating() {
  if (creating != null)
    creating.tempEdge.image = createShape(LINE, creating.start.image.getParams()[0], creating.start.image.getParams()[1], mouseX, mouseY);
}

Edge getExistingEdge(Vertex start, Vertex end) {
  for (Edge e : eList) {
    if((start.vNumber == e.start.vNumber && end.vNumber == e.end.vNumber) || (start.vNumber == e.end.vNumber && end.vNumber == e.start.vNumber)) {
       return e;
    }
  }
  return null;
}

int getEdgeCount() {
  int sum = 0;
  for (Edge e : eList) {
    sum += e.multiplicity;
  }
  return sum;
}

int getAvaliableVNumber() {
  int i = 0;
  while (true && vList.size() > 0) {
    for (Vertex v : vList) {
      if(i == v.vNumber) {
        break;
      }
      if(v.vNumber == vList.get(vList.size() - 1).vNumber) {
        return i;
      }
    }
    i++;
  }
  return i;
}


//Rest of Reccomended Features:
String getComponents() {
  //Method: When a node is visited, mark in bool table visited, visit every node possible, skip starting nodes already visited. Conceptual help from:https://www.geeksforgeeks.org/connected-components-in-an-undirected-graph/
  String result = "";
  boolean[] visited = new boolean[getHighestvNumber() + 1];
  //print((getHighestvNumber()+1) + "and" + visited.length + "\n");
  ArrayList<ArrayList<String>> components = new ArrayList<ArrayList<String>>();
  for(int i = 0; i < vList.size(); i++) {
    //println("Length: " + visited.length);
    if(!visited[vList.get(i).vNumber]) {
      ArrayList<String> newComponent = new ArrayList<String>();
      components.add(newComponent);
      //print("Counterb: " + i + "\n");
      exploreComponent(vList.get(i), visited, newComponent);
      //print("Countera: " + i + "\n");
    }
  }
  int c = 1;
  for (ArrayList<String> comp : components) {
    Collections.sort(comp);
    result += "Component" + c + ": ";
    for (String vertN : comp) {
      result += vertN + " ";
    }
    result += "\n";
    c++;
  }
  return result;
}

void exploreComponent(Vertex v, boolean[] visited, ArrayList<String> component) {
  visited[v.vNumber] = true;
  component.add(Integer.toString(v.vNumber));
  
  for (Vertex adj : v.getAdjacentVerts()) {
    if(!visited[adj.vNumber] && adj.vNumber != v.vNumber) {
      exploreComponent(adj, visited, component);
    }
  }
}

void printBridgeList() {
  
}

boolean isBipartite() {
  return false;
}

//Directed edges mode (directed edge inherits from edge)

int getHighestvNumber() {
  int highestNum = -1;
  for (Vertex v : vList) {
    if (v.vNumber > highestNum) {
      highestNum = v.vNumber;
    }
  }
  return highestNum;
}

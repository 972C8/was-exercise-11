//illuminance controller agent

// Set to true if you want to test the real lab environment, rather than a simulation
manifest_goal_description_real(false).

/*
* The URL of the W3C Web of Things Thing Description (WoT TD) of a lab environment
* Simulated lab WoT TD: "https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/interactions-lab.ttl"
* Real lab WoT TD: Get in touch with us by email to acquire access to it!
*/

/* Initial beliefs and rules */

// the agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a lab environment to be learnt
learning_lab_environment("https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/interactions-lab.ttl").

// Bonus task: Add real lab environment
real_lab_environment("https://raw.githubusercontent.com/Interactions-HSG/example-tds/was/tds/interactions-lab-real.ttl").

// the agent believes that the task that takes place in the 1st workstation requires an indoor illuminance
// level of Rank 2, and the task that takes place in the 2nd workstation requires an indoor illumincance 
// level of Rank 3. Modify the belief so that the agent can learn to handle different goals.

// Add different goal descriptions for training. As we loop through all for training, you may reduce or increase the list.
// training_goal_descriptions([0,0],[0,1],[0,2],[0,3],[1,0],[1,1],[1,2],[1,3],[2,0],[2,1],[2,2],[2,3],[3,0],[3,1],[3,2],[3,3]).
// training_goal_descriptions([[0,2],[2,1],[3,3]]).
training_goal_descriptions([[2,3]]). // use fewer for faster learning (not always optimal..)

// Bonus task: Real goal description for testing in the lab
manifest_goal_description([2,3]).

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that there is a WoT TD of a lab environment located at Url, and that 
 * the tasks taking place in the workstations require indoor illuminance levels of Rank Z1Level and Z2Level
 * respectively
 * Body: (currently) creates a QLearnerArtifact and a ThingArtifact for learning and acting on the lab environment.
*/
@start
+!start
  : learning_lab_environment(Url)
  & real_lab_environment(UrlReal)
  & training_goal_descriptions(GoalDescriptionList)
  & manifest_goal_description(ManifestGoalDescription)
  & manifest_goal_description_real(ManifestGoalDescriptionInRealLab) <-
  
  .print("Hello world");

  // creates a QLearner artifact for learning the lab Thing described by the W3C WoT TD located at URL
  makeArtifact("qlearner", "tools.QLearner", [Url], QLArtId);

  // Calculate Q for all training goal descriptions. Use fewer if you want to speed up the learning process.
  for ( .member([Z1Level,Z2Level],GoalDescriptionList) ) {
    .print("New goal description: Z1Level=", Z1Level, " and Z2Level=",Z2Level);
    calculateQ([Z1Level,Z2Level], 3, 0.2, 0.9, 0.3, 100, ManifestGoalDescriptionInRealLab)[artifact_id(QLArtId)];
  }
  
  // Create a ThingArtifact for the simulated (or real) lab environment
  // The ThingArtifact is used to read the state of the lab and to invoke actions on it
  if (ManifestGoalDescriptionInRealLab) {
    makeArtifact("lab", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [UrlReal], LabArtId);
  } else {
    makeArtifact("lab", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Url], LabArtId);
  }

  // Parse the ManifestGoalDescription into variables for easier use
  .nth(0, ManifestGoalDescription, ManifestGoalDescriptionZ1Level);
  .nth(1, ManifestGoalDescription, ManifestGoalDescriptionZ2Level);

  // Try to manifest the goal description in the simulated or real lab
  -+manifest_goal_description_success(false);
  for ( .range(I,1,10) & manifest_goal_description_success(TrueFalse) & TrueFalse == false ) {

    .print("-------------------------------");
    .print("Attempting with Try #", I);

    readProperty("https://example.org/was#Status", Key, Value)[artifact_id(LabArtId)];

    // Debug print to see the exact structure
    //.print("Key=", Key, " Value=", Value);

    /*
    TYPICAL RESPONSE FOR SIMULATED LAB:

    Key=[
    "http://example.org/was#Z2Level",
    "http://example.org/was#EnergyCost",
    "http://example.org/was#Z1Blinds",
    "http://example.org/was#Hour",
    "http://example.org/was#Sunshine",
    "http://example.org/was#Z2Light",
    "http://example.org/was#Z1Light",
    "http://example.org/was#TotalEnergyCost",
    "http://example.org/was#Z2Blinds",
    "http://example.org/was#Z1Level"]
    Value=[
    484.4003606632392,
    5,
    true,
    16.19999999999996,
    616.645120521592,
    false,
    false,
    1012,
    true,
    484.4003606632392
    ]
    */

    /*
    Typical response for real lab: -> Hour is missing, which shifts the indeces!!
    Key=[
    "http://example.org/was#Z2Level",
    "http://example.org/was#EnergyCost",
    "http://example.org/was#Z1Blinds",
    "http://example.org/was#Sunshine",
    "http://example.org/was#Z2Light",
    "http://example.org/was#Z1Light",
    "http://example.org/was#TotalEnergyCost",
    "http://example.org/was#Z2Blinds",
    "http://example.org/was#Z1Level"]
    Value=[
    86.66666412,
    100,
    false,
    301.92,
    true,
    false,
    703651,
    false,
    149.1666565]
    */

    // Parse the values from the response according to the value in ManifestGoalDescriptionInRealLabBoolean variable.
    if (ManifestGoalDescriptionInRealLab) {
      .nth(0, Value, Z2Level);
      .nth(2, Value, Z1Blinds);
      .nth(3, Value, Sunshine);
      .nth(4, Value, Z2Light);
      .nth(5, Value, Z1Light);
      .nth(7, Value, Z2Blinds);
      .nth(8, Value, Z1Level);

      .print("Z1Level=", Z1Level, " Z2Level=", Z2Level, " Z1Blinds=", Z1Blinds, " Sunshine=", Sunshine, " Z2Light=", Z2Light, " Z1Light=", Z1Light, " Z2Blinds=", Z2Blinds);
    } else {
      .nth(0, Value, Z2Level);
      .nth(1, Value, Z1Blinds);
      .nth(2, Value, Hour);
      .nth(3, Value, Sunshine);
      .nth(4, Value, Z2Light);
      .nth(5, Value, Z1Light);
      .nth(6, Value, Z2Blinds);
      .nth(7, Value, Z1Level);

      .print("Z1Level=", Z1Level, " Z2Level=", Z2Level, " Z1Blinds=", Z1Blinds, " Hour=", Hour, " Sunshine=", Sunshine, " Z2Light=", Z2Light, " Z1Light=", Z1Light, " Z2Blinds=", Z2Blinds);
    }
    
    // Pre-process values
    discretizeLightLevel(Z1Level, DiscZ1Level);
    discretizeLightLevel(Z2Level, DiscZ2Level);
    discretizeSunshine(Sunshine, DiscSunshine);

    .nth(0, DiscZ2Level, DiscretizedZ2Level);
    .nth(0, DiscZ1Level, DiscretizedZ1Level);
    .nth(0, DiscSunshine, DiscretizedSunshine);

    if (DiscretizedZ1Level == ManifestGoalDescriptionZ1Level & DiscretizedZ2Level == ManifestGoalDescriptionZ2Level) {
      .print("Manifestation successful. Z1Level=", DiscretizedZ1Level, " Z2Level=", DiscretizedZ2Level, " ManifestGoalDescriptionZ1Level=", ManifestGoalDescriptionZ1Level, " ManifestGoalDescriptionZ2Level=", ManifestGoalDescriptionZ2Level);
      -+manifest_goal_description_success(true);
    } else {
      //TODO: fix issue that the values are not boolean

      // Convert values to boolean before passing to getActionFromState
      .eval(Z1LightBool, Z1Light == "true" | Z1Light == 1);
      .eval(Z2LightBool, Z2Light == "true" | Z2Light == 1);
      .eval(Z1BlindsBool, Z1Blinds == "true" | Z1Blinds == 1);
      .eval(Z2BlindsBool, Z2Blinds == "true" | Z2Blinds == 1);

      getActionFromState(ManifestGoalDescription, 
                        [DiscretizedZ1Level,
                         DiscretizedZ2Level,
                         Z1LightBool,
                         Z2LightBool,
                         Z1BlindsBool,
                         Z2BlindsBool,
                         DiscretizedSunshine], 
                        ActionTag, PayloadTags, Payload);

      .print("Manifestation not yet as desired. Performing next action with ActionTag=", ActionTag, " PayloadTags=", PayloadTags, " Payload=", Payload);
      invokeAction(ActionTag, PayloadTags, Payload)[artifact_id(LabArtId)];
      
      // Wait until executing the next action. Make sure to wait longer in the real lab (60s vs. 1s)
      if (ManifestGoalDescriptionInRealLab) {
        .print("Waiting 60s for the action to be executed in the real lab.");
        .wait(60000);
      } else {
        .wait(1000);
      }
    }
  }
  -+manifest_goal_description_success(false).
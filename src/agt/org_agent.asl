// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoring_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

/* Initial goals */
!start. // the agent has the goal to start

/*
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Starting organization setup with org: ", OrgName, " group: ", GroupName, " scheme: ", SchemeName);

  // T1.1 - Create and join an organization workspace named after the organization
  createWorkspace(OrgName);
  joinWorkspace(OrgName, OrgWsp);
  .print("T1.1 - Created and joined workspace: ", OrgName);

  // T1.2 - Create and focus on an Organization Board artifact
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgBoard);
  focus(OrgBoard);
  .print("T1.2 - Created OrgBoard: ", OrgBoard);

  // T1.3 - Use the Organization Board to create and focus on Group Board and Scheme Board artifacts
  // Create a Group Board artifact
  .print("T1.3 - Attempting to create group: ", GroupName);
  createGroup(GroupName, GroupName, GroupBoard);
  focus(GroupBoard);
  .print("T1.3 - Group created successfully");

  // Create a Scheme Board artifact
  .print("T1.3 - Creating scheme: ", SchemeName);
  createScheme(SchemeName, SchemeName, SchemeBoard);
  focus(SchemeBoard);
  .print("T1.3 - Scheme created successfully");

  // T1.4 - Broadcast that a new organization workspace is available
  .broadcast(tell, org_workspace_available(OrgName));
  .print("T1.4 - Broadcasted organization workspace availability");

  .print("T1.5 - Waiting for group formation status");
  .wait(5000);
  !check_group_formation(GroupBoard, OrgBoard);
  .



+!check_group_formation(GroupBoard, OrgBoard) : group_name(GroupName) & org_name(OrgName) <-
  // Ensure we're focusing on the artifacts
  focus(GroupBoard);
  focus(OrgBoard);

  // Monitor the formationStatus observable property
  ?formationStatus(Status);
  .print("Group formation status: ", Status);

  // Query all roles and their cardinalities from the org specification
  for (role_cardinality(Role, Min, Max)) {
    // Count current players for this role
    .count(play(_, Role, _), PlayersCount);

    // Check if the role needs more players (less than minimum)
    if (PlayersCount < Min) {
      .print("Role '", Role, "' needs more players. Current: ", PlayersCount, ", Minimum: ", Min);
      .broadcast(tell, available_role(Role, OrgName));
    } elif (PlayersCount >= Max) { // Jason syntax uses 'elif' not 'else if'
      .print("Role '", Role, "' has reached maximum capacity (", Max, ")");
      .abolish(available_role(Role, OrgName));
      .broadcast(untell, available_role(Role, OrgName));
    }
  }

  // Check if formation is complete
  if (Status == ok) {
    .print("T2.1 Reasoning on Group Formation - Group is now well-formed!");
    // Use the correct operation addScheme on the GroupBoard artifact
    ?sch_name(SchemeName);
    addScheme(SchemeName)[artifact_id(GroupBoard)];

    .print("Group is now responsible for the monitoring scheme");
  } else {
    .print("T2.1 Reasoning on Group Formation - Group is not yet well-formed. Checking again in 15 seconds.");
    .wait(15000);
    !check_group_formation(GroupBoard, OrgBoard);
  }
.




/*
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

/*
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)].

/*
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }
// acting agent

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Initial goals */
!start. // the agent has the goal to start

/*
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

/*
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celsius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: converts the temperature from Celsius to binary degrees that are compatible with the
 * movement of the robotic arm. Then, manifests the temperature with the robotic arm
*/
@manifest_temperature_plan
+!manifest_temperature : temperature(Celsius) & robot_td(Location) <-
	.print("I will manifest the temperature: ", Celsius);
	!ensure_converter_artifact(ConverterId);
	convert(Celsius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)];
	.print("Temperature Manifesting (moving robotic arm to): ", Degrees);
	!ensure_leubot_artifact(Location, Leubot1Id);
	invokeAction("https://ci.mines-stetienne.fr/kg/ontology#SetWristAngle", ["https://www.w3.org/2019/wot/json-schema#IntegerSchema"], [Degrees])[artifact_id(Leubot1Id)].

// Plan to ensure the converter artifact exists
+!ensure_converter_artifact(ArtId) <-
	lookupArtifact("converter", ArtId).

// Failure plan if the converter artifact doesn't exist
-!ensure_converter_artifact(ArtId) <-
	makeArtifact("converter", "tools.Converter", [], ArtId).

// Plan to ensure the leubot artifact exists
+!ensure_leubot_artifact(Location, ArtId) <-
	lookupArtifact("leubot1", ArtId).

// Failure plan if the leubot artifact doesn't exist
-!ensure_leubot_artifact(Location, ArtId) <-
	makeArtifact("leubot1", "org.hyperagents.jacamo.artifacts.wot.ThingArtifact", [Location, true], ArtId).


// Plan to react when a message about an available organization workspace is received
+org_workspace_available(OrgName)[source(Sender)] <-
    .print("Received information about available workspace: ", OrgName, " from ", Sender);
    !join_org_workspace(OrgName).

// Plan to join an organization workspace
+!join_org_workspace(OrgName) <-
    .print("Joining workspace: ", OrgName);
    joinWorkspace(OrgName, OrgWsp);
    .print("Joined workspace: ", OrgName, " with ID: ", OrgWsp);

    // Look up the OrgBoard artifact to observe organization properties
    lookupArtifact(OrgName, OrgBoard);
    focus(OrgBoard);
    .print("Focused on OrgBoard to observe organization properties").

// Plan to react when a message about an available role is received
+available_role(Role, OrgName)[source(Sender)] <-
    .print("Role available: ", Role, " in organization: ", OrgName, " from ", Sender);
    .print("I'm interested in adopting the role: ", Role);
    !adopt_role(Role, OrgName);
    .

// Plan to adopt a role in an organization
+!adopt_role(Role, OrgName) <-
    .print("Adopting role: ", Role, " in organization: ", OrgName);

    // Look up the GroupBoard artifact to interact with the group
    lookupArtifact("monitoring_team", GroupBoard);
    focus(GroupBoard);
    .print("Focused on GroupBoard to interact with the group");

    // Adopt the role
    adoptRole(Role)[artifact_id(GroupBoard)];
    .print("Successfully adopted role: ", Role).

// React when the agent starts playing a role in the organization
+play(Me, Role, Group)[source(percept)] <-
    .print("I (", Me, ") am now playing the role: ", Role, " in group: ", Group).

// React when temperature information is received
+temperature(Celsius) <-
    .print("Received temperature information: ", Celsius, "°C");
    !manifest_temperature.

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }
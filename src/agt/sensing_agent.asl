// sensing agent

/* Initial beliefs and rules */

/* Custom rules for role adoption */
can_achieve(read_temperature) :- true.  // The agent can achieve read_temperature goal

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
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
    .print("I will read the temperature");
    makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
    focus(WeatherStationId); // focuses on the weather station artifact
    readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
    .print("Temperature Reading (Celcius): ", Celcius);
    .broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* T2.1 - Plan for reacting to organization workspace availability */
+org_workspace_available(OrgName) <-
    .print("T2.1 Reasoning for Role Adoption - Organization workspace available: ", OrgName);
    // a) Join the workspace
    joinWorkspace(OrgName, OrgWsp);
    .print("T2.1.a Reasoning for Role Adoption - Joined workspace: ", OrgName);

    // b) Focus on organizational artifacts to observe properties and events
    lookupArtifact(OrgName, OrgBoard);
    focus(OrgBoard);

    lookupArtifact("monitoring_team", GroupBoard);
    focus(GroupBoard);

    lookupArtifact("monitoring_scheme", SchemeBoard);
    focus(SchemeBoard);

    .print("T2.1.b Reasoning for Role Adoption - Focused on organization artifacts");

    // Now that we have organizational beliefs, reason about roles to adopt
    !adopt_relevant_roles.

/* T2.2 - Plan for adopting relevant roles based on agent capabilities */
+!adopt_relevant_roles <-
    .print("T2.2 Reasoning for Role Adoption - Reasoning about roles to adopt...");
    // Find roles related to goals the agent can achieve
    for (can_achieve(Goal) & mission_goal(Mission, Goal) & role_mission(Role, Scheme, Mission)) {
        .print("T2.2 Reasoning for Role Adoption - I can achieve goal ", Goal, " in mission ", Mission, " for role ", Role);
        // Adopt the role if we can achieve its goals
        adoptRole(Role);
        .print("T2.2 Reasoning for Role Adoption - Adopted role ", Role);
    }.

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }
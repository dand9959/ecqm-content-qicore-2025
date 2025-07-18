library CQMCommon version '4.1.000'

using QICore version '6.0.0'

include FHIRHelpers version '4.4.000' called FHIRHelpers
include QICoreCommon version '4.0.000' called QICoreCommon

codesystem DiagnosisRole: 'http://terminology.hl7.org/CodeSystem/diagnosis-role'
codesystem "Diagnosis Type": 'http://terminology.hl7.org/CodeSystem/ex-diagnosistype'
codesystem "Procedure Type": 'http://terminology.hl7.org/CodeSystem/ex-procedure-type'
codesystem "Present On Admission Indicators": 'https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Payment/HospitalAcqCond/Coding'

valueset "Emergency Department Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.292'
valueset "Encounter Inpatient": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.666.5.307'
valueset "Intensive Care Unit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1029.206'
valueset "Observation Services": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1111.143'
valueset "Outpatient Surgery Service": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1110.38'
valueset "Present on Admission or Clinically Undetermined": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1147.197'

code "Billing": 'billing' from DiagnosisRole display 'Billing'
code "Admitting Diagnosis": 'admitting' from "Diagnosis Type" display 'Admitting Diagnosis'
code "Clinical Diagnosis": 'clinical' from "Diagnosis Type" display 'Clinical Diagnosis'
code "Differential Diagnosis": 'differential' from "Diagnosis Type" display 'Differential Diagnosis'
code "Discharge Diagnosis": 'discharge' from "Diagnosis Type" display 'Discharge Diagnosis'
code "Laboratory Diagnosis": 'laboratory' from "Diagnosis Type" display 'Laboratory Diagnosis'
code "Nursing Diagnosis": 'nursing' from "Diagnosis Type" display 'Nursing Diagnosis'
code "Prenatal Diagnosis": 'prenatal' from "Diagnosis Type" display 'Prenatal Diagnosis'
code "Principal Diagnosis": 'principal' from "Diagnosis Type" display 'Principal Diagnosis'
code "Radiology Diagnosis": 'radiology' from "Diagnosis Type" display 'Radiology Diagnosis'
code "Remote Diagnosis": 'remote' from "Diagnosis Type" display 'Remote Diagnosis'
code "Retrospective Diagnosis": 'retrospective' from "Diagnosis Type" display 'Retrospetive Diagnosis'
code "Self Diagnosis": 'self' from "Diagnosis Type" display 'Self Diagnosis'
code "Primary procedure": 'primary' from "Procedure Type" display 'Primary procedure'
code "POA-Y": 'Y' from "Present On Admission Indicators" display 'POA-Y'
code "POA-N": 'N' from "Present On Admission Indicators" display 'POA-N'
code "POA-W": 'W' from "Present On Admission Indicators" display 'POA-W'
code "POA-1": '1' from "Present On Admission Indicators" display 'POA-1'
code "POA-U": 'U' from "Present On Admission Indicators" display 'POA-U'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Inpatient Encounter":
  [Encounter: "Encounter Inpatient"] EncounterInpatient
    where EncounterInpatient.status = 'finished'
      and EncounterInpatient.period ends during day of "Measurement Period"

/*
@description: Returns an interval of date values extracted from the input interval of date-time values
@comment: This function returns an interval constructed using the `date from` extractor on the start
and end values of the input date-time interval. Note that using a precision specifier such as `day of`
as part of a timing phrase is preferred to communicate intent to perform day-level comparison, as well
as for general readability.
*/
define function "ToDateInterval"(period Interval<DateTime>):
  Interval[date from start of period, date from end of period]

/*
@description: Calculates the difference in calendar days between the start and end of the given interval.
@deprecated: This function in deprecated. Use the fluent function `lengthInDays()` instead.
*/
define function "LengthInDays"(Value Interval<DateTime> ):
  difference in days between start of Value and end of Value

/*
@description: Calculates the difference in calendar days between the start and end of the given interval.
*/
define fluent function lengthInDays(Value Interval<DateTime> ):
  difference in days between start of Value and end of Value

/*
@description: Returns the most recent emergency department visit, if any, that occurs 1 hour or less prior to the given encounter.
@deprecated: This function is deprecated. Use the fluent function `edVisit()` instead.
*/
define function "ED Visit"(TheEncounter Encounter ):
  Last(
    [Encounter: "Emergency Department Visit"] EDVisit
      where EDVisit.status = 'finished'
        and EDVisit.period ends 1 hour or less on or before start of TheEncounter.period
      sort by end of period
    )

/*
@description: Returns the most recent emergency department visit, if any, that occurs 1 hour or less prior to the given encounter.
*/
define fluent function edVisit(TheEncounter Encounter ):
  Last(
    [Encounter: "Emergency Department Visit"] EDVisit
      where EDVisit.status = 'finished'
        and EDVisit.period ends 1 hour or less on or before start of TheEncounter.period
      sort by end of period
    )

/*
@description: Hospitalization returns the total interval for admission to discharge for the given encounter, or for the admission of any immediately prior emergency department visit to the discharge of the given encounter.
@deprecated: This function is deprecated. Use the fluent function `hospitalization()` instead.
*/
define function "Hospitalization"(TheEncounter Encounter ):
  ( "ED Visit"(TheEncounter) ) X
    return
        if X is null then TheEncounter.period
        else Interval[start of X.period, end of TheEncounter.period)

/*
@description: Hospitalization returns the total interval for admission to discharge for the given encounter, or for the admission of any immediately prior emergency department visit to the discharge of the given encounter.
*/
define fluent function hospitalization(TheEncounter Encounter ):
  (TheEncounter."edVisit"()) X
    return
        if X is null then TheEncounter.period
        else Interval[start of X.period, end of TheEncounter.period]

/*
@description: Returns list of all locations within an encounter, including locations for immediately prior ED visit.
@deprecated: This function is deprecated. Use the fluent function `hospitalizationLocations()` instead.
*/
define function "Hospitalization Locations"(TheEncounter Encounter ):
  ( "ED Visit"(TheEncounter) ) EDEncounter
    return
        if EDEncounter is null then TheEncounter.location
        else flatten { EDEncounter.location, TheEncounter.location }

/*
@description: Returns list of all locations within an encounter, including locations for immediately prior ED visit.
*/
define fluent function hospitalizationLocations(TheEncounter Encounter ):
  ( TheEncounter."edVisit"()) EDEncounter
    return
        if EDEncounter is null then TheEncounter.location
        else flatten { EDEncounter.location, TheEncounter.location }

/*
@description: Returns the length of stay in days (i.e. the number of days between admission and discharge) for the given encounter, or from the admission of any immediately prior emergency department visit to the discharge of the encounter
@deprecated: This function is deprecated. Use the fluent function `hospitalizationLengthOfStay()` instead.
*/
define function "Hospitalization Length of Stay"(TheEncounter Encounter ):
  LengthInDays("Hospitalization"(TheEncounter))

/*
@description: Returns the length of stay in days (i.e. the number of days between admission and discharge) for the given encounter, or from the admission of any immediately prior emergency department visit to the discharge of the encounter
*/
define fluent function hospitalizationLengthOfStay(TheEncounter Encounter ):
   TheEncounter."hospitalization"()."lengthInDays"()

/*
@description: Returns admission time for an encounter or for immediately prior emergency department visit.
@deprecated: This function is deprecated. Use the fluent function `hospitalAdmissionTime()` instead.
*/
define function "Hospital Admission Time"(TheEncounter Encounter ):
  start of "Hospitalization"(TheEncounter)

/*
@description: Returns admission time for an encounter or for immediately prior emergency department visit.
*/
define fluent function hospitalAdmissionTime(TheEncounter Encounter ):
  start of (TheEncounter."hospitalization"())

/*
@description: Hospital Discharge Time returns the discharge time for an encounter
@deprecated: This function is deprecated. Use the fluent function `hospitalDischargeTime()` instead.
*/
define function "Hospital Discharge Time"(TheEncounter Encounter ):
  end of TheEncounter.period

/*
@description: Hospital Discharge Time returns the discharge time for an encounter
*/
define fluent function hospitalDischargeTime(TheEncounter Encounter ):
  end of TheEncounter.period

/*
@description: Returns earliest arrival time for an encounter including any prior ED visit.
@deprecated: This function is deprecated. Use the fluent function `hospitalArrivalTime()` instead.
*/
define function "Hospital Arrival Time"(TheEncounter Encounter ):
  start of First(
  	    ("Hospitalization Locations"(TheEncounter) ) HospitalLocation
  			sort by start of period
  	).period

/*
@description: Returns earliest arrival time for an encounter including any prior ED visit.
*/
define fluent function hospitalArrivalTime(TheEncounter Encounter ):
  start of First(
  	    (TheEncounter."hospitalizationLocations"()) HospitalLocation
  			sort by start of period
  	).period

/*
@description: Returns the latest departure time for encounter including any prior ED visit.
@deprecated: This function is deprecated. Use the fluent function `hospitalDepartureTime()` instead.
*/
define function "Hospital Departure Time"(TheEncounter Encounter):
	end of Last(
	    ( "Hospitalization Locations"(TheEncounter) ) HospitalLocation
			sort by start of period
	).period

/*
@description: Returns the latest departure time for encounter including any prior ED visit.
*/
define fluent function hospitalDepartureTime(TheEncounter Encounter):
	end of Last(
	    (TheEncounter."hospitalizationLocations"()) HospitalLocation
			sort by start of period
	).period

/*
@description: Returns the emergency department arrival time for the encounter.
@deprecated. This function is deprecated. Use the fluent function `emergencyDepartmentArrivalTime()` instead.
*/
define function "Emergency Department Arrival Time"(TheEncounter Encounter):
	start of (
	    singleton from (
	        ( "Hospitalization Locations"(TheEncounter) ) HospitalLocation
				where GetLocation(HospitalLocation.location).type in "Emergency Department Visit"
		)
	).period

/*
@description: Returns the emergency department arrival time for the encounter.
*/
define fluent function emergencyDepartmentArrivalTime(TheEncounter Encounter):
	start of (
	    singleton from (
	        ( (TheEncounter."hospitalizationLocations"()) ) HospitalLocation
				where GetLocation(HospitalLocation.location).type in "Emergency Department Visit"
		)
	).period

/*
@description: Hospitalization with Observation and Outpatient Surgery Service returns the total interval from the start of any immediately prior emergency department visit, outpatient surgery visit or observation visit to the discharge of the given encounter.
@deprecated: This function is deprecated. Use the fluent function `hospitalizationWithObservationAndOutpatientSurgeryService()` instead.
*/
define function "HospitalizationWithObservationAndOutpatientSurgeryService"(TheEncounter "Encounter" ):
  TheEncounter Visit
	  let ObsVisit: Last([Encounter: "Observation Services"] LastObs
		  	where LastObs.status = 'finished'
          and LastObs.period ends 1 hour or less on or before start of Visit.period
			  sort by	end of period
    	),
    	VisitStart: Coalesce(start of ObsVisit.period, start of Visit.period),
    	EDVisit: Last([Encounter: "Emergency Department Visit"] LastED
			  where LastED.status = 'finished'
          and LastED.period ends 1 hour or less on or before VisitStart
			  sort by	end of period
    	),
    	VisitStartWithED: Coalesce(start of EDVisit.period, VisitStart),
    	OutpatientSurgeryVisit: Last([Encounter: "Outpatient Surgery Service"] LastSurgeryOP
			  where LastSurgeryOP.period ends 1 hour or less on or before VisitStartWithED
			  sort by	end of period
    	)
  	return Interval[Coalesce(start of OutpatientSurgeryVisit.period, VisitStartWithED), end of Visit.period]

/*
@description: Hospitalization with Observation and Outpatient Surgery Service returns the total interval from the start of any immediately prior emergency department visit, outpatient surgery visit or observation visit to the discharge of the given encounter.
*/
define fluent function hospitalizationWithObservationAndOutpatientSurgeryService(TheEncounter "Encounter" ):
  TheEncounter Visit
	  let ObsVisit: Last([Encounter: "Observation Services"] LastObs
		  	where LastObs.status = 'finished'
          and LastObs.period ends 1 hour or less on or before start of Visit.period
			  sort by	end of period
    	),
    	VisitStart: Coalesce(start of ObsVisit.period, start of Visit.period),
    	EDVisit: Last([Encounter: "Emergency Department Visit"] LastED
			  where LastED.status = 'finished'
          and LastED.period ends 1 hour or less on or before VisitStart
			  sort by	end of period
    	),
    	VisitStartWithED: Coalesce(start of EDVisit.period, VisitStart),
    	OutpatientSurgeryVisit: Last([Encounter: "Outpatient Surgery Service"] LastSurgeryOP
			  where LastSurgeryOP.period ends 1 hour or less on or before VisitStartWithED
			  sort by	end of period
    	)
  	return Interval[Coalesce(start of OutpatientSurgeryVisit.period, VisitStartWithED), end of Visit.period]

/*
@description: Hospitalization with Observation returns the total interval from the start of any immediately prior emergency department visit through the observation visit to the discharge of the given encounter
@deprecated: This function is deprecated. Use the fluent function `hospitalizationWithObservation()` instead.
*/
define function "HospitalizationWithObservation"(TheEncounter Encounter ):
  TheEncounter Visit
  		let ObsVisit: Last([Encounter: "Observation Services"] LastObs
  				where LastObs.status = 'finished'
            and LastObs.period ends 1 hour or less on or before start of Visit.period
  				sort by end of period
  			),
  			VisitStart: Coalesce(start of ObsVisit.period, start of Visit.period),
  			EDVisit: Last([Encounter: "Emergency Department Visit"] LastED
  				where LastED.status = 'finished'
            and LastED.period ends 1 hour or less on or before VisitStart
  				sort by end of period
  			)
  		return Interval[Coalesce(start of EDVisit.period, VisitStart), end of Visit.period]

/*
@description: Hospitalization with Observation returns the total interval from the start of any immediately prior emergency department visit through the observation visit to the discharge of the given encounter
*/
define fluent function hospitalizationWithObservation(TheEncounter Encounter ):
  TheEncounter Visit
  		let ObsVisit: Last([Encounter: "Observation Services"] LastObs
  				where LastObs.status = 'finished'
            and LastObs.period ends 1 hour or less on or before start of Visit.period
  				sort by end of period
  			),
  			VisitStart: Coalesce(start of ObsVisit.period, start of Visit.period),
  			EDVisit: Last([Encounter: "Emergency Department Visit"] LastED
  				where LastED.status = 'finished'
            and LastED.period ends 1 hour or less on or before VisitStart
  				sort by end of period
  			)
  		return Interval[Coalesce(start of EDVisit.period, VisitStart), end of Visit.period]

/*
@description: Hospitalization with Observation Length of Stay returns the length in days from the start of any immediately prior emergency department visit through the observation visit to the discharge of the given encounter
@deprecated: This function is deprecated. Use the fluent function `hospitalizationWithObservationLengthofStay()` instead.
*/
define function "HospitalizationWithObservationLengthofStay"(TheEncounter "Encounter" ):
  "LengthInDays"("HospitalizationWithObservation"(TheEncounter))

/*
@description: Hospitalization with Observation Length of Stay returns the length in days from the start of any immediately prior emergency department visit through the observation visit to the discharge of the given encounter
*/
define fluent function hospitalizationWithObservationLengthofStay(TheEncounter "Encounter" ):
  ((TheEncounter."hospitalizationWithObservation"()."lengthInDays"()))

/*
@description: First Inpatient Intensive Care Unit returns the first intensive care unit for the given encounter, without considering any immediately prior emergency department visit.
@deprecated: This function is deprecated. Use the fluent function `firstInpatientIntensiveCareUnit()` instead.
*/
define function "FirstInpatientIntensiveCareUnit"(Encounter Encounter ):
  First((Encounter.location)HospitalLocation
  			where GetLocation(HospitalLocation.location).type in "Intensive Care Unit"
  				and HospitalLocation.period during Encounter.period
  			sort by start of period
  	)

/*
@description: First Inpatient Intensive Care Unit returns the first intensive care unit for the given encounter, without considering any immediately prior emergency department visit.
*/
define fluent function firstInpatientIntensiveCareUnit(Encounter Encounter ):
  First((Encounter.location)HospitalLocation
  			where GetLocation(HospitalLocation.location).type in "Intensive Care Unit"
  				and HospitalLocation.period during Encounter.period
  			sort by start of period
  	)

/*
@description: Returns the Condition resource referenced by the `diagnosis.condition` element of the Encounter
@deprecated: This function is deprecated. Use the fluent function `encounterDiagnosis()` instead.
*/
define function "EncounterDiagnosis"(Encounter Encounter ):
  Encounter.diagnosis D
	return singleton from (([ConditionEncounterDiagnosis] union [ConditionProblemsHealthConcerns]) C where D.condition.references(C.id))

/*  
@description: Returns the Condition resources referenced by the diagnosis element of the Encounter  
*/
define fluent function encounterDiagnosis(Encounter Encounter ):
  Encounter.reasonReference D
    return singleton from (([ConditionEncounterDiagnosis] union [ConditionProblemsHealthConcerns]) C where D.references(C.id))


/*
@description: Returns the Condition resource for the given reference
@deprecated: This function is deprecated. Use the fluent function `getCondition()` instead
*/
define function "GetCondition"(reference Reference):
  singleton from (([ConditionEncounterDiagnosis] union [ConditionProblemsHealthConcerns]) C where reference.references(C.id))

/*
@description: Returns the Condition resource for the given reference
*/
define fluent function getCondition(reference Reference):
  singleton from (([ConditionEncounterDiagnosis] union [ConditionProblemsHealthConcerns]) C where reference.references(C.id))

/*
@description: Returns the condition that is specified as the principal diagnosis for the encounter
@deprecated: This function is deprecated. Use the fluent function `principalDiagnosis()` instead.
*/
define function "PrincipalDiagnosis"(Encounter Encounter):
	singleton from (
	(Encounter.diagnosis D where D.rank = 1 and D.use ~ "Billing") PD
      return singleton from (([ConditionEncounterDiagnosis] union [ConditionProblemsHealthConcerns]) C where PD.condition.references(C.id))
	)

/*
@description: Returns the claim diagnosis element that is specified as the principal diagnosis for the encounter
 @comment: See the QICore 6 Authoring Patterns discussion on [Principal Diagnosis and Present on Admission](https://github.com/cqframework/CQL-Formatting-and-Usage-Wiki/wiki/Authoring-Patterns-QICore-v6.0.0#conditions-present-on-admission-and-principal-diagnoses) for more information
*/
define fluent function principalDiagnosis(encounter Encounter):
singleton from (
     (encounter.claimDiagnosis()) CD
       where CD.type.includesCode("Principal Diagnosis")
   )
/*
@description: Returns the claim diagnosis elements for the given encounter
@comment: See the QICore 6 Authoring Patterns discussion on [Principal Diagnosis and Present on Admission](https://github.com/cqframework/CQL-Formatting-and-Usage-Wiki/wiki/Authoring-Patterns-QICore-v6.0.0#conditions-present-on-admission-and-principal-diagnoses) for more information
*/
define fluent function claimDiagnosis(encounter Encounter):
  encounter E
    let 
      claim: ([Claim] C where C.status = 'active' and C.use = 'claim' and exists (C.item I where I.encounter.references(E))),
      claimItem: (claim.item I where I.encounter.references(E))
    return claim.diagnosis D where D.sequence in claimItem.diagnosisSequence


/*
 @description: Returns the condition that is specified as the principal diagnosis for the encounter and has a code in the given valueSet.
 @comment: See the QICore 6 Authoring Patterns discussion on [Principal Diagnosis and Present on Admission](https://github.com/cqframework/CQL-Formatting-and-Usage-Wiki/wiki/Authoring-Patterns-QICore-v6.0.0#conditions-present-on-admission-and-principal-diagnoses) for more information
 */
 define fluent function hasPrincipalDiagnosisOf(encounter Encounter, valueSet ValueSet):
   (encounter.principalDiagnosis()) PD
     return PD.diagnosis in valueSet
       or PD.diagnosis.getCondition().code in valueSet

/*
 @description: Returns true if the given diagnosis is present on admission, based on the given poaValueSet
 @comment: See the QICore 6 Authoring Patterns discussion on [Principal Diagnosis and Present on Admission](https://github.com/cqframework/CQL-Formatting-and-Usage-Wiki/wiki/Authoring-Patterns-QICore-v6.0.0#conditions-present-on-admission-and-principal-diagnoses) for more information
 */
 define fluent function isDiagnosisPresentOnAdmission(encounter Encounter, diagnosisValueSet ValueSet, poaValueSet ValueSet):
   exists (
     (encounter.claimDiagnosis()) CD
       where CD.onAdmission in poaValueSet
         and (
           CD.diagnosis in diagnosisValueSet
             or CD.diagnosis.getCondition().code in diagnosisValueSet
         )
   )

/*
@description: Returns the Location resource specified by the given reference
@deprecated: This function is deprecated. Use the fluent function `getLocation()` instead.
*/
define function "GetLocation"(reference Reference):
  singleton from (
    [Location] L where reference.references(L)
  )

/*
@description: Returns the Location resource specified by the given reference.
*/
define fluent function getLocation(reference Reference):
  singleton from (
    [Location] L where reference.references(L)
  )

/*
@description: Returns the medication code for the given MedicationRequest
@deprecated: This function is deprecated. Use the fluent function `getMedicationCode()` instead.
*/
define function "GetMedicationCode"(request MedicationRequest):
  if request.medication is Concept then
  	  request.medication as Concept
  	else
  	  (singleton from ([Medication] M where request.medication.references(M))).code

/*
@description: Returns the medication code for the given MedicationRequest
*/
define fluent function getMedicationCode(request MedicationRequest):
  if request.medication is Concept then
  	  request.medication as Concept
  	else
  	  (singleton from ([Medication] M where request.medication.references(M))).code
  	  
/*
@description: Returns the claim procedure elements for the given encounter
*/
define fluent function principalProcedure(encounter Encounter):  	  
  	 encounter E
  	 let 
        claim: [Claim] C where C.status = 'active' and C.use = 'claim' and exists (C.item I where I.encounter.references(E)),
        claimItem: claim.item I where I.encounter.references(E),
        princProcedure: singleton from (claim.procedure P where P.sequence in claimItem.procedureSequence and P.type.includesCode("Primary procedure"))
    return princProcedure
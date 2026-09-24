# lucentBase and ISO 19156 (Observations, Measurements and Samples)

lucentBase follows **ISO 19156:2023, *Observations, measurements and samples***
(OMS), published by ISO and the OGC as
[OGC Abstract Specification Topic 20](https://docs.ogc.org/as/20-082r4/20-082r4.html).
OMS is the standard conceptual model for "someone determined a value of a
property of something, using some procedure". Environmental monitoring, geology,
hydrology and many research data infrastructures (INSPIRE, OGC SensorThings)
build on it.

The rule for lucentBase is:

> **Structure follows OMS. Every structural deviation has a documented reason
> in this file. Names may differ** (they are listed below as well).

"Extensions" are things OMS does not cover at all, such as orders or the
planning of work. They add to the model without contradicting it.

When the schema changes, this file changes with it.


## Mapping

### Observations

| OMS | lucentBase | Notes |
|---|---|---|
| Observation | `observation` | One value of one property. The act it belongs to is its `action`. |
| phenomenonTime | `observation.phenomenon_time`, `phenomenon_time_of()` | Derived when not stored, see deviation D4. |
| resultTime | `observation.result_time` | |
| result | `observation.result_numeric`, `result_text`, `result_boolean`, `result_timestamp` | Exactly one is set, matching the property's `result_type` (OMS 8.2.15). |
| unit of measure (8.2.16) | `observation.id_unit`, `method_property.id_unit` | Always present for numeric results; filled from the method if not given. |
| resultQuality | `method_property.uncertainty`, `lod`, `loq`; `observation.censoring` | See D6. |
| featureOfInterest / proximateFeatureOfInterest | `action.id_sample` | Always a sample, see D1. |
| ultimateFeatureOfInterest | `sampled_feature_of(sample)` → `feature` | |
| observedProperty | `observation.id_observed_property` | Must be determined by the action's method (OMS 8.2.14); a trigger enforces it. |
| ObservableProperty | `observed_property` | `definition_uri` can point to a public vocabulary. |
| observingProcedure | `action.id_method_version` | |
| Procedure, ObservingProcedure | `method` (kind `observation`) + `method_version` | Versioned, see E3. |
| ObservingCapability | `method_property` | Which properties a method version determines, and how well. |
| observer | `action.id_performer`, `action_device` | Recorded per act, see D5. |
| relatedObservation | `observation_input` | Only the role "input of a calculation", see D7. |
| ObservationCollection (with memberCharacteristics) | `action` of kind `observation` | The observations of one action share feature of interest, procedure, observer and time. |
| parameter (NamedValue) | observations in the same action | See D3. |
| validTime | none | See D8. |
| Host, Deployment | none | See D9. |
| A calculation as the procedure (7.1.3: "an algorithm, a computation") | `method_property.formula`, `calculate_action()` | Calculated values are ordinary observations with recorded inputs. |

### Samples

| OMS | lucentBase | Notes |
|---|---|---|
| Sample | `sample` | |
| SpatialSample | `sample` with `sample_kind = 'spatial'` | Sampling points, transects, plots. |
| SpatialSample.shape | `sample.location` | A geometry with its EPSG code as SRID. |
| MaterialSample | `sample` with `sample_kind = 'material'` | Bottles, bags, cores, aliquots. |
| MaterialSample.size | `sample.size` + `sample.id_size_unit` | |
| MaterialSample.storageLocation | `sample.id_storage_location` → `storage_location` | Current location only; history comes with the audit trail. |
| MaterialSample.sourceLocation | `sample.location`, or the location of a source sample | |
| sampleType (codelist) | `sample.id_matrix` → `matrix` | The community-specific type: surface water, soil, air. |
| StatisticalSample | none | See D2. |
| sampledFeature | `sample.id_sampled_feature`, inherited through sources | See D1. |
| relatedSample | `sample_source` | Only the relation "obtained from", see D7. |
| Sampling | `action` of kind `sampling`, on the sample it creates | Includes splitting and compositing, as in OMS 11.3.2 (examples 1, 8, 10). |
| Sampling.featureOfInterest | the sources of the created sample (`sample_source`), or its sampled feature | A composite has several sources, as OMS allows. |
| Sampling.time | `action.started_at`, `action.finished_at` | |
| Sampling.samplingLocation | `sample.location` | |
| Sampler | `action.id_performer`, `action_device` | A person or a device, as in OMS. |
| SamplingProcedure | `method` (kind `sampling`) | |
| PreparationStep | `action` of kind `preparation` | |
| PreparationProcedure | `method` (kind `preparation`) | |
| SampleCollection | none | Orders and lineage group samples already. |
| domain feature (GenericDomainFeature) | `feature` | The lake, the field, the well. |


## Deviations and their reasons

**D1: The feature of interest of an observation is always a sample.**
OMS allows any feature. In a lab, everything that is observed has been sampled:
a bottle, or a place (a spatial sample) for in-situ measurements. Restricting
the feature of interest to `sample` gives a real foreign key instead of a
reference that could point to any table. Nothing is lost: any domain feature
can be observed through a spatial sample that covers it, and the ultimate
feature of interest is always reachable through `sampled_feature_of()`.
A sample has at most one sampled feature of its own (OMS: one or more).
Samples obtained from other samples inherit it, and a composite of samples
from several features has all of them in its lineage.

**D2: No statistical samples.**
They describe subsets of populations (OMS 13.5), which is not what
environmental and academic labs handle. They can be added as a third
`sample_kind` if the need comes up.

**D3: Event parameters are observations too.**
OMS attaches "arbitrary event-specific parameters" (NamedValue) to an
observation, such as a dilution factor. lucentBase records them as
observations of their own property in the same action. That gives them a
type, a unit, a review and an audit trail, and formulas can use them. OMS
itself notes that explicitly modelled information interoperates better than
the generic parameter mechanism (12.2.3).

**D4: phenomenonTime is derived when it can be.**
OMS requires exactly one phenomenonTime per observation. For a measurement on
a material sample in the lab it is the sampling time (OMS 8.2.4, example 2),
which the sample's sampling action already records. Copying it into every
observation would store one fact many times. So `phenomenon_time` is only
stored when it cannot be derived (time series, in-situ values that differ
from the action time), and `phenomenon_time_of()` always delivers one:
the stored value, else the sampling time of the material sample (the
earliest sampling in its lineage, so an aliquot reports when its bottle was
filled), else the start of the action for spatial samples.

**D5: The observer is recorded per act, not per observation.**
In a lab, one act (an ICP-OES run, a field measurement) is carried out by one
person with one set of devices, and produces many observations. Storing the
observer on each observation would repeat the same fact. An export assigns
the action's performer and devices to each of its observations.

**D6: Result quality lives mostly with the method.**
OMS has a free-form resultQuality per observation. lucentBase stores what
labs actually state: measurement uncertainty, LOD and LOQ per method version
and property, and whether a device only reported a limit (`censoring`). An
observation's quality is derived from these. Per-observation quality flags
beyond that can be added once a real case needs them.

**D7: Related samples and observations have one relation type each.**
OMS qualifies relatedSample and relatedObservation with a free role name.
lucentBase models the one relation it uses for each as its own table:
"obtained from" (`sample_source`) and "input of a calculation"
(`observation_input`). A table per relation type keeps foreign keys and rules
meaningful. Other relation types become tables of their own when needed.

**D8: No validTime.**
OMS itself calls it a forecasting concept (8.2.5). Lab results do not expire.

**D9: No Host or Deployment.**
They describe platforms and the placement of sensors on them, such as a
monitoring station with installed probes. Small labs record which devices
were used (`action_device`); that is the Observer part. Host and Deployment
belong in a later module for continuous monitoring.


## Extensions beyond OMS

OMS describes what happened. A LIMS also has to plan and organize work.
These parts extend the model without changing it:

- **E1, the lifecycle.** Actions are planned before they happen, and they
  depend on each other (`method_prerequisite`), bring each other along
  (`method_implication`) or close a sample for good (`method.is_final`).
  Once finished, an action is what OMS describes.
- **E2, handling actions.** Receipt, storage and disposal happen to samples
  but are neither sampling, preparation nor observation. They are actions of
  kind `handling`.
- **E3, method versions.** OMS has no versioning. Labs must be able to say
  which version of a method produced a result, so each action records its
  `method_version`, and versions that have been used are frozen.
- **E4, orders, customers, review and reports.**
- **E5, units with conversions.** OMS only requires that a unit is given.
  lucentBase also knows how to convert between units of one dimension, and
  records UCUM codes for exchange with other systems.


## Names that differ

| OMS | lucentBase | Why |
|---|---|---|
| Procedure | `method` | `PROCEDURE` is a reserved word in MariaDB, and "method" is the term ISO/IEC 17025 and lab staff use. |
| ObservableProperty | `observed_property` | Reads naturally in queries ("the observed property of an observation"). |
| Observation (the act) | `action` | lucentLIMS's original name for everything that happens to a sample. `observation` is the single result, as in OMS. |
| Sampling, PreparationStep | `action` (by method kind) | One lifecycle for every act. |
| relatedSample | `sample_source` | Names the one relation it stands for. |
| relatedObservation | `observation_input` | Names the one relation it stands for. |
| domain feature | `feature` | Short; it is the feature in the ISO 19101 sense. |


## Outlook: speaking the standard

The OGC SensorThings API is a REST interface built on the same model. A
read-only SensorThings endpoint for lucentBase would map `observed_property` to
ObservedProperty, `sample` to FeatureOfInterest, `observation` to Observation,
devices to Sensor, and the observations of one method on one sample to a
Datastream. Because the structure already matches, that mapping is a set of
views, not a conversion.

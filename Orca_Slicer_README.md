# Orca Slicer Notes for QiDi Plus4

Short notes for Orca Slicer quirks, support issues, and workarounds I want to remember.

## Current profile direction

Main goal:

- Keep good visible quality.
- Increase speed where it is safer.
- Watch support behavior closely on ASA.
- Always inspect support preview before wasting filament.

Safer speed gains:

```json
{
  "outer_wall_speed": "95",
  "inner_wall_speed": "150",
  "sparse_infill_speed": "250",
  "internal_solid_infill_speed": "200",
  "travel_speed": "450",
  "top_surface_speed": "84",
  "bridge_speed": "42",
  "internal_bridge_speed": "56"
}
```

## Orca support limitation: curved / arced undersides

Orca can struggle with support interface under curved, arced, angled, or organic undersides.

The support may look present, but the first model layer above support can still print in air, string, curl, or fail to touch the support interface correctly.

Main issue:

- `Support/object XY distance` can pull the support interface away from curved or angled geometry.
- `Top Z distance` alone may not fix it.
- This is worse on curved or arced undersides than flat supported areas.

Related issue:

- [OrcaSlicer #11341 - Support interface distance issue on curved / angled surfaces](https://github.com/OrcaSlicer/OrcaSlicer/issues/11341)

## Quick workaround values

For curved or arced ASA support problems, try:

```json
{
  "support_top_z_distance": "0.05",
  "support_interface_top_layers": "3",
  "support_interface_spacing": "0.5",
  "support_object_xy_distance": "0.15",
  "support_object_first_layer_gap": "0.08",
  "bridge_no_support": "0",
  "thick_bridges": "0",
  "thick_internal_bridges": "0"
}
```

If support still pulls away from the model:

```json
{
  "support_object_xy_distance": "0.05"
}
```

If support sticks too much:

```json
{
  "support_object_xy_distance": "0.2"
}
```

If the model layer is still floating vertically above support:

```json
{
  "support_top_z_distance": "0"
}
```

Risk: lower gaps can make supports harder to remove or scar the part.

## Top interface spacing note

Do not assume ugly supported layers mean the interface needs to be denser.

`Top interface spacing = 0.5mm` can be fine.

Only reduce it if the support roof itself looks too sparse:

```json
{
  "support_interface_spacing": "0.3"
}
```

More aggressive:

```json
{
  "support_interface_spacing": "0.2"
}
```

## Support interface direction issues

Orca may also behave weirdly with support interface direction.

Symptoms:

- Interface lines may run the wrong direction for the part.
- Rotating the model may not rotate support interface behavior as expected.
- The first model layer may run parallel to the interface lines and sag between them.

Related issues:

- [OrcaSlicer #7513 - Support interface pattern angle issue](https://github.com/OrcaSlicer/OrcaSlicer/issues/7513)
- [OrcaSlicer #10458 - Better support interface angle control request](https://github.com/OrcaSlicer/OrcaSlicer/issues/10458)

Workarounds:

- Rotate the model.
- Try a different support interface pattern.
- Inspect the exact first model layer above support.
- Avoid relying on Orca supports for bad curved undersides when possible.

## Cura comparison

Cura may handle some of this better because it has support distance priority behavior such as `Z Overrides X/Y`.

Related links:

- [Bambu Studio #2529 - X/Y support distance priority](https://github.com/bambulab/BambuStudio/issues/2529)
- [Cura #19527 - Support distance priority bug report](https://github.com/Ultimaker/Cura/issues/19527)

If Orca keeps failing on curved underside support, try Cura before wasting more ASA.

Useful Cura concept:

```text
Support Distance Priority: Z Overrides X/Y
Support Z Distance: 0.05mm to 0.10mm
Support Interface: Enabled
Support Interface Density: 80% to 100%
```

## Source patch note

A real fix may require Orca source changes.

Post-processing scripts are not a good fix because they run after slicing. They can change speeds, temperatures, fan commands, or flow, but they cannot properly regenerate missing support-interface geometry.

## Support debug checklist

Before printing support-heavy ASA parts:

1. Slice the model.
2. Preview the exact first model layer above support.
3. Check curved or arced undersides carefully.
4. If the support interface pulls away, suspect Orca issue #11341.
5. Try lowering `Support/object XY distance`.
6. Only densify interface spacing if the interface roof itself is too sparse.
7. Try a different model rotation if interface direction looks bad.
8. Try Cura if Orca preview still looks wrong.

## Reminder

Bad supported-layer quality on curved undersides may be an Orca limitation, not just bad tuning.
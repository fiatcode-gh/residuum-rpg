# U16 Placeholder Slot Contract

U16 may introduce future-art hosts, but not future art.

## Principle

A placeholder is a **consumer geometry proof**, not temporary artwork.

It must prove that later `flow-assets` candidates can be inserted without moving layout.

## Required record per slot

| Field | Required |
|---|---|
| consumer | exact widget/file |
| semantic purpose | what adjacent text/state carries |
| rendered width | dp |
| rendered height | dp |
| shape | circle/square/rect |
| internal safe area | dp/insets |
| alignment | exact |
| alpha | opaque/transparent-capable |
| tint | none / explicitly permitted |
| filter quality | if image-backed later |
| absent fallback | neutral geometry |
| hit target | separate from art slot where interactive |
| evidence | target-device frame |

## Candidate slot families for U16 planning

Local recon should decide whether each is actually needed:

- action icon slot;
- recent-event category pictogram slot;
- status/utility symbol slot;
- compact timeline symbol slot.

Do not create a slot just because the mock has an icon.

## Existing U15 row host

U15 already established one non-crawl consumer:

- leading envelope: 44×44 dp;
- inner medallion well: 36×36 dp;
- transparent, circular, untinted host.

Do not duplicate a competing row-medallion geometry.

## `flow-assets` boundary

After U16 is merged and consumers are stable, a later asset unit may run `flow-assets`:

1. derive `ASSET.md` from the real consumer;
2. stage candidates;
3. conform deterministically;
4. promote deliberately;
5. accept in the actual screen.

U16 itself stops before step 1 becomes generation work.

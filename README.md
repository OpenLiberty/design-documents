# Open Liberty Design Documents

This repository is used to store design documents for the Open Liberty org that are meant to be open source or viewable to the general public. It is intended for design documents related to any products in the [Open Liberty org](https://github.com/OpenLiberty).

## UFOs

**Template:** [ufo-template.md](templates/ufo-template.md)

## Directory structure

- Features should have a dedicated folder under the appropriate product directory.
- Dedicated folders should be named using the issue number of the repository that the tracking feature issue is in:
  
  ```
  open-liberty/
  ├── 31046/
  │   ├── images/
  │   │   └── ...
  │   └── ufo.md
  ```

  In this example, the `31046` folder corresponds to feature https://github.com/OpenLiberty/open-liberty/issues/31046.

  The design document SHOULD be named `ufo.md`. There's no hard requirement on that, but I'm trying to look ahead and would like to impose consistency that might make things simpler in the future.

## Branches

### Recommendations

- Draft your documents in a feature branch.
  
  Feature 31046, for example, might have its initial drafts being worked in a `31046-log-file-rotation` branch tracked by this repository. Anyone collaborating on the design can do the usual Git activities to make revisions and push updates to the feature branch.

- Once your documents are complete (or largely complete), merge the feature branch into `main`. However that gets done is up to you.

# Open Liberty Design Documents

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
---
tags: [index]
---

# 🎯 Projects

> Active work with a clear **goal and end**. Finished → move to `04 Archive/`.

## All projects
```dataview
TABLE status, deadline
FROM "01 Projects"
WHERE file.name != "Projects"
SORT deadline ASC
```

> 📁 **Layout:** `01 Projects/<Project>/` — or group one level deep, e.g. `01 Projects/<Client>/<Project>/`.
> Add a `repo:` field to a project note's frontmatter to surface its code path at session start.

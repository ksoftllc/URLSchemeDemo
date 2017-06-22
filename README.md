# URLSchemeDemo
Example app that accepts URL scheme calls only from app whose bundle starts with com.countermind.miclinic.webiz

URL formmat is `<scheme>://<user>:<password>@<host>?<query>`, where:
- `scheme` = webiz
- `user` = webiz username
- `password` = webiz password for username
- `host` = action to perform
- `query` = url query string

 Example:  
   `webiz://e218f4400d966d1ee51ebc676b115ca9:53615cfa7a9e6dd1fcd9bc15ca6fe4a8@lookup?last=smith&amp;first=james&amp;dob=12-12-1999&amp;callback=miclinc://e218f4400d966d1ee51ebc676b115ca9:53615cfa7a9e6dd1fcd9bc15ca6fe4a8@launcher`
- `scheme` = webiz
- `user` = e218f4400d966d1ee51ebc676b115ca9
- `password` = 53615cfa7a9e6dd1fcd9bc15ca6fe4a8
- `host` = lookup
- `query` = last=smith&amp;first=james&amp;dob=12-12-1999&amp;callback=miclinic://e218f4400d966d1ee51ebc676b115ca9:53615cfa7a9e6dd1fcd9bc15ca6fe4a8@launcher
  - last = smith
  - first = james
  - dob = 12-12-1999
  - callback = miclinic://e218f4400d966d1ee51ebc676b115ca9:53615cfa7a9e6dd1fcd9bc15ca6fe4a8@launcher
  
  In this case, the callback query parameter is a complete URL for calling back to the calling app. If the parameter is present, the app will attempt to create a URL and open it.

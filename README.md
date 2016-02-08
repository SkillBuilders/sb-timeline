# sb-timeline
SkillBuilders Timeline is a free plugin built for apex 5

##Description
SkillBuilders Timeline is an alternative view for reporting date or time sensitive information. Each record will get an event slide and will be marked in a timeline scrubber. Users can select individual events from the scrubber or click through the timeline one event at a time.

View the [Demo](https://apex.skillbuilders.com/demo/f?p=PLUGIN_DEMOS:SB_TIMELINE)

##Credits
Most of the hard work was performed by the good folks at [knightlab](http://timeline.knightlab.com) in producing the javascript library for the widget.

##Features
What to expect from the integration between timeline and APEX.

###Display Timeline
The region consumes a sql statment and will output the results in a timeline region.

####Basic Example:
```sql
  select
    ename,    -- Title Column
    hiredate  -- Date Column
  from
    emp
```  
####Include an Image:
```sql
  select
    ename,    -- Title Column
    hiredate, -- Date Column
    'i/image/employee/'||empno||'.jpg' image_path -- Media URL Column
  from
    emp
```  
####Group Employees by Department:
```sql
  select
    ename,    -- Title Column
    hiredate, -- Date Column
    'i/image/employee/'||empno||'.jpg' image_path, -- Media URL Column
    deptno    -- Group Column
  from
    emp
```

### Media Types
Timeline supports the following media types
* Flickr
* Instagram
* Images
* Vimeo
* YouTube
* Vine
* Daily Motion
* Soundcloud
* Spotify
* Storify
* Document Cloud
* Google Maps
* Google Docs
* iFrames
* Blockquotes
* Twitter
* Website Links

###AJAX Enabled
Timeline will respond as expected to the native apex refresh event and will submit items specified in the "Page Items to Submit" property.

###No Data Found
If no data is retrived the Timeline will use the regions `No Data Found` property

###Groups/Swimlanes
For every distinct value within the group column another swimlane will be added to the timeline scrubber. While it supports many swimlanes it is best to keep the number of groups to three or less

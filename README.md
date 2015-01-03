What is it?
===========

A Puppet module that ensures EC2 ephemeral disks are mounted.

Released under the Apache 2.0 licence

Usage:
------

trusted_node_data = true is required

To mount the disks:
<pre>
  include aws_mount
</pre>

Known Issues:
-------------
* 8 and 24 disks not supported at this time

Contribute:
-----------
* Fork it
* Create a topic branch
* Improve/fix (with spec tests)
* Push new topic branch
* Submit a PR

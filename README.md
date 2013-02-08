# What is Ajo?
AJO (“garlic” in Spanish) stands for Asynchronous Job Operator. This useful tool was designed and developed to provide a transparent gateway between your web, application or service and an HPC system.

AJO moves your executions to a Distributed Resource Management
Application API ([DRMAA](http://www.drmaa.org/)) compatible queue
system, such as [Grid Engine family](http://gridengine.org/blog/) or
[TORQUE](http://www.adaptivecomputing.com/products/open-source/torque/), allowing you to submit, execute and retrieve any kind of greedy task in an easy and fast way.

![Ajo functionality](http://rdlab.lsi.upc.edu/images/stories/ajo/EsquemaAJO.png)

# Why Ajo?
Several applications and researchers' projects require a public service for data exchange and customer access. However, a HPC system must be a closed system for security and performance reasons. Hence, we have offered them a way to connect to the HPC system in a seamless way.

Through a command line interface, AJO conceals technical issues such as establishing communication with the HPC system or querying for the job status. Therefore, any existing application can expand its computational capabilities beyond a single server computational capability easily with minor changes in its source code: just build the proper configuration file and call the AJO script.

# How does it work?
AJO uses a simple three-command scheme to manage the data transport to/from the HPC system and the execution of every task. The configuration file contains all the information needed to fulfil the execution, as well as the data paths.
*Warning: All the tasks performed by AJO are stored in the HPC users' home ($HOME/.executions) by default.*
**Submit:** This process copies your data to the queue system, builds
the execution script and submits the job to the queue system. It returns
a secure *Token Id* that allows you to check and retrieve results.

![Submission process](http://rdlab.lsi.upc.edu/images/stories/ajo/SubmitAJO.png)

**Query:** The query command checks the status of one defined execution,
identified by the *Token Id*. Cipher techniques are used to generate
this *Token Id* to ensure trustability.

![Query process](http://rdlab.lsi.upc.edu/images/stories/ajo/QueryAJO.png)

**Retrieve:** The retrieve command returns the results of a finished execution, identified by *Token Id*.

![Retrieval process](http://rdlab.lsi.upc.edu/images/stories/ajo/RetrieveAJO.png)

**Cancel:** The cancel option lets you abort a previously submitted job
identified by *Token Id*.

**Delete:** It is also possible to delete a previously submitted job by
issuing the delete command and the *Token Id*.

# License
Licensed under a [GNU General Public License v3.0](http://www.gnu.org/licenses/gpl.html).

# Project's webpage
The official project webpage: http://rdlab.lsi.upc.edu/ajo

# Documentation
User's manual is available
[here](http://rdlab.lsi.upc.edu/index.php/es/servicios/documentacion.html).

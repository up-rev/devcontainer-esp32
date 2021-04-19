README 
======

This is a development container for developing ESP32 projects. It includes all of the dependencies for ESP32 development and `mrtutils <https://mrt.readthedocs.io/en/latest/>`_

Once the container is open, run:

.. code-block:: bash 

     ./opt/esp/idf/export.sh 


Stages
------

There are two stages to the build. The first sets up a dev environment, and the second enables it to be a jenkins node 

.. code-block:: bash 

    docker build . --target=devstaget 


Args
----

Passwords:
~~~~~~~~~~

You can set the passwords for the ``dev`` and ``jenkins`` users with ``DEV_PW`` and ``JENKINS_PW`` 

IDF Version
~~~~~~~~~~~
To build image for a branch or tag of IDF:

.. code-block:: bash 

    build . --build-arg IDF_CLONE_BRANCH_OR_TAG=name

Or from a specific commit:

.. code-block:: bash 

    build . --build-arg IDF_CHECKOUT_REF=commit-id
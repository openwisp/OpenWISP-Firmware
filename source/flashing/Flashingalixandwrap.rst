FlashingAlixAndWrap
===================

.. figure:: http://www.metrix.net/images/alix3d2.gif
   :alt: alix

   alix
Flashing via Disk Dump utility
------------------------------

In order to keep an Alix or a WRAP working with OWF you need to write a
compact flash with a simple flash reader. You can use "dd" utility:

.. raw:: html

   <pre>
     ~: dd if=/path/to/firmware of=/dev/compact_flash_disk
   </pre>

If you want to see the progress during the dump you can use pipebench

.. raw:: html

   <pre>
     ~:  dd if=/path/to/firmware | pipebench | dd of=/dev/compact_flash_disk
   </pre>

That's it ;)

Now you can power up your device and try to boot into OWF.

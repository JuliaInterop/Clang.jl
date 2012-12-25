### Todo

* Generate wrappers for remaining functions
* Move the init and parse stuff to Julia (pointers only)
* Get rid of C++ dependency by replacing std::vector with 
  pure C container.
* fix get_string: sometimes there is a double-free when called in certain order.

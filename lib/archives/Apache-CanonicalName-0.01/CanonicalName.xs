#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "mod_perl.h"

char *
_construct_url(Apache r, char *uri) {
    return ap_construct_url(r->pool, uri, r);
}

MODULE = Apache::CanonicalName   PACKAGE = Apache::CanonicalName

PROTOTYPES: DISABLE

char *
_construct_url(r, uri)
  Apache r;
  char *uri;
  CODE:
    RETVAL = _construct_url(r, uri);
  OUTPUT:
    RETVAL

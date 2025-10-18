#ifndef fputil_H
#define fputil_H

#include "float.h"
#include <limits>

// Floating point comparisons 
static const double TOLERANCE = 0.000001;    // floating point tolerance

inline bool fless(double a, double b) { return (a < b - TOLERANCE); }
inline bool fgreater(double a, double b) { return (a > b + TOLERANCE); }
inline bool fequal(double a, double b) { return (a >= b - TOLERANCE) && (a <= b+TOLERANCE); }

inline double min(double a, double b) { return fless(a, b)?a:b; }
inline double max(double a, double b) { return fless(a, b)?b:a; }

#endif

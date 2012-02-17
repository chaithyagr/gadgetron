#pragma once

#include "senseOperator.h"
#include "cuMatrixOperator_macros.h"
#include "gpupmri_export.h"
#include "cuNDArray.h"
#include "vector_td.h"

template<class REAL, unsigned int D> class EXPORTGPUPMRI cuSenseOperator 
  : public senseOperator<REAL, D, cuNDArray< typename complext<REAL>::Type> >
{

public:

  cuSenseOperator() : senseOperator<REAL, D, cuNDArray< _complext> >() { set_device(-1); }
  virtual ~cuSenseOperator() {}

  typedef typename complext<REAL>::Type _complext;

  virtual int mult_M( cuNDArray< _complext>* in, cuNDArray< _complext>* out, bool accumulate = false ) = 0;
  virtual int mult_MH( cuNDArray< _complext>* in, cuNDArray< _complext>* out, bool accumulate = false ) = 0;
    
  virtual int mult_csm( cuNDArray< _complext>* in, cuNDArray< _complext>* out );
  virtual int mult_csm_conj_sum( cuNDArray< _complext>* in, cuNDArray< _complext>* out);

  DECLARE_MATRIX_OPERATOR_DEVICE_SUPPORT(cuSenseOperator)
};

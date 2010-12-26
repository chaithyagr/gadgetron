#ifndef GADGETSTREAMCONTROLLER_H
#define GADGETSTREAMCONTROLLER_H

#include "ace/Log_Msg.h"
#include "ace/Reactor.h"
#include "ace/SOCK_Stream.h"
#include "ace/Stream.h"
#include "ace/Message_Queue.h"

#include <complex>

#include "GadgetStreamConfigurator.h"
#include "GadgetSocketSender.h"
#include "NDArray.h"

class GadgetStreamController : public ACE_Event_Handler
{
public:
  ACE_SOCK_Stream &peer (void) { return this->sock_; }


  int open (void);

  virtual ACE_HANDLE get_handle (void) const { 
    return this->sock_.get_handle (); 
  }

  virtual int handle_input (ACE_HANDLE fd = ACE_INVALID_HANDLE);
  virtual int handle_output (ACE_HANDLE fd = ACE_INVALID_HANDLE);
  virtual int handle_close (ACE_HANDLE handle,
                            ACE_Reactor_Mask close_mask);

  virtual int output_ready(ACE_Message_Block* mb) { return this->output_->putq (mb); }

protected:
  ACE_SOCK_Stream sock_;
  ACE_Stream<ACE_MT_SYNCH> stream_;
  bool stream_configured_;
  GadgetSocketSender* output_;

  virtual int read_configuration();
  virtual int read_acquisition();
  //virtual int write_image(GadgetMessageImage* imageh, NDArray< std::complex<float> >* data);
  //virtual int write_acquisition(GadgetMessageAcquisition* imgh, NDArray< std::complex<float> >* data);

};

#endif //GADGETSTREAMCONTROLLER_H
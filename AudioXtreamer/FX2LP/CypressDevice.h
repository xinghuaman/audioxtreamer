#pragma once

#include "UsbDev\UsbDev.h"
#include "UsbBackend.h"
#include "midi\midi.h"


class CypressDevice : public UsbDevice
{
public:
  explicit CypressDevice(UsbDeviceClient & client, ASIOSettings::Settings & params);
  ~CypressDevice() override;

  bool Open() override;
  bool Start() override;
  bool Stop(bool wait) override;
  bool Close() override;
  bool IsRunning() override;
  bool IsPresent() override;

  bool GetStatus(UsbDeviceStatus &status) override;
  uint32_t GetSampleRate() override;
  bool ConfigureDevice() override { return false; }
  

private:

  void main();
  HANDLE hth_Worker;
  HANDLE mExitHandle;
  HANDLE mASIOHandle;

  static void StaticWorkerThread(void* arg)
  {
    CypressDevice *inst = static_cast<CypressDevice*>(arg);
    if (inst != nullptr)
      inst->main();
  }

  uint16_t nrSamples;

  bool ProcessHdr(uint8_t* pHdr);
  void InitTxHeaders(uint8_t* ptr, uint32_t Samples);
  void UpdateClient();

  uint32_t RxProgress;
  uint16_t InStride;
  uint16_t INBuffSize;
  void RxIsochCB();

  uint16_t OUTBuffSize;
  uint16_t OUTStride;
  void TxIsochCB();

  void TimerCB();

  void AsioClientCB();

  XferReq *mRxRequests;
  XferReq *mTxRequests;
  uint8_t** asioInPtr;
  uint8_t** asioOutPtr;

  uint8_t mTxReqIdx;
  uint8_t mRxReqIdx;

  uint8_t mDefOutEP;
  uint8_t mDefInEP;
  uint8_t* mBitstream;
  uint32_t mResourceSize;

  HANDLE mDevHandle;
  HANDLE mFileHandle;
  HANDLE hSem;
  UsbDeviceStatus mDevStatus;
  MidiIO midi;

  //the Sample where IsoIn data gets transfered
  uint8_t RxBuff;

  //The buffer we sent to the asio client
  uint8_t AsioBuff;

  //The buffer where we have completed samples to IsoOut
  uint8_t TxBuff;

  //The offset(in samples) of the partial buffer we managed to transmit
  uint16_t TxBuffPos;

  //throttles the output based on the input pace and if no audio is available, helps send as many silence samples
  uint16_t IsoTxSamples;

  bool ClientActive;



};

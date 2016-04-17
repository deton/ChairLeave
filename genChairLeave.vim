:%s/bleprox_/chairleave_/g
:%s/TRACE(TRACE_INFO, MODULE_ID_BLEAPP, \(.*\), TVF_D(0)/ble_trace0(\1/
:%s/TRACE(TRACE_INFO, MODULE_ID_BLEAPP, \(.*\), TVF_D(\([^)]*\))/ble_trace1(\1, \2/
:%s/TRACE(TRACE_INFO, MODULE_ID_BLEAPP, \(.*\), TVF_BB(\([^)]*\))/ble_trace2(\1, \2/
:%s/TRACE(TRACE_INFO, MODULE_ID_BLEAPP, \(.*\), TVF_BBW(\([^)]*\))/ble_trace3(\1, \2/
:%s/TRACE(TRACE_INFO, MODULE_ID_BLEAPP, \(.*\), TVF_BBBB(\([^)]*\))/ble_trace4(\1, \2/
Q
1099,1101d
1039,1041d
965a
    if (isLeave)
    {
        ble_trace0("chairleave not start advertising\n");
        return;
    }
.
945,947d
776,781d
447,453d
440a
void chairleave_FineTimeout(UINT32 finecount)
{
.
439a
}
.
437,438c
        // if not connected && not advertising
        if (proxAppState->chairleave_con_handle == 0 &&
                bleprofile_GetDiscoverable() != HIGH_UNDIRECTED_DISCOVERABLE &&
                bleprofile_GetDiscoverable() != LOW_UNDIRECTED_DISCOVERABLE)
        {
            ble_trace0("chairleave start advertising\n");
            proxAppState->chairleave_powersave = 0;
            chairleave_connDown(); // start advertising
        }
.
435c
    else
.
432,433c
        if (proxAppState->chairleave_con_handle)
        {
            ble_trace0("chairleave disconnecting\n");
            blecm_disconnect(BT_ERROR_CODE_CONNECTION_TERMINATED_BY_LOCAL_HOST);
        }
        else if (bleprofile_GetDiscoverable() == HIGH_UNDIRECTED_DISCOVERABLE ||
                 bleprofile_GetDiscoverable() == LOW_UNDIRECTED_DISCOVERABLE)
        {
            ble_trace0("chairleave stop advertising\n");
            bleprofile_Discoverable(NO_DISCOVERABLE, NULL);
        }
.
430c
void chairleave_onLeave(void)
{
    if (isLeave)
.
423,428c
#if USE_ADC
    UINT32 v = adc_readVoltage(adc_convertGPIOtoADCInput(SENSOR_PIN));
    ble_trace1("ADC %d\n", v);
    UINT8 leaveNew = (v < SENSOR_THRESHOLD) ? 1 : 0;
#else
    BYTE v = gpio_getPinInput((SW_PIN) / 16, (SW_PIN) % 16);
    ble_trace1("SW %d\n", v);
    // GPIO_PIN_INPUT_HIGH = pullup = SW-OFF = leave
    UINT8 leaveNew = (v == GPIO_PIN_INPUT_HIGH) ? 1 : 0;
#endif
    // LED OFF(OUTPUT_HIGH) while leave
    gpio_setPinOutput((SENSOR_LED_PIN) / 16, (SENSOR_LED_PIN) % 16,
            leaveNew ? GPIO_PIN_OUTPUT_HIGH : GPIO_PIN_OUTPUT_LOW);
    leaveRecent = (leaveRecent << 1) | leaveNew;
    BOOL prev = isLeave;
    if (isLeave)
    {
        if ((leaveRecent & 0x01) == 0) // (recent 1 data) == 0
        {
            isLeave = 0;
        }
    }
    else
    {
        if (leaveRecent >= 0xff) // (recent 8 data) == 1
        {
            isLeave = 1;
        }
    }
    if (isLeave != prev)
    {
        chairleave_onLeave();
    }
}
.
421c
void chairleave_pollChairLeave(void)
.
414a
    chairleave_pollChairLeave();

.
408,412d
388,390c
    chairleave_connDown();
.
382,385c
    // Disable GPIO double bonded with the ones we plan to use in this app.
    gpio_configurePin((GPIO_PIN_P38) / 16, (GPIO_PIN_P38) % 16, GPIO_INPUT_DISABLE, 0);
    gpio_configurePin((SENSOR_LED_PIN) / 16, (SENSOR_LED_PIN) % 16, GPIO_OUTPUT_ENABLE, GPIO_PIN_OUTPUT_HIGH);
#if USE_ADC
    adc_config();
#else
    gpio_configurePin((SW_PIN) / 16, (SW_PIN) % 16, GPIO_INPUT_ENABLE | GPIO_PULL_UP, 0);
.
330,335d
324a
BOOL isLeave = 0;
UINT8 leaveRecent = 0;

APPLICATION_INIT()
{
    bleapp_set_cfg((UINT8 *)chairleave_db_data, sizeof(chairleave_db_data), (void *)&chairleave_cfg,
       (void *)&chairleave_puart_cfg, (void *)&chairleave_gpio_cfg, chairleave_Create);
}
.
323c
tProxAppState sProcAppState;
tProxAppState *proxAppState = &sProcAppState;
.
293d
270,283d
259,264d
257d
254c
    {1, 0, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}, // UINT8 gpio_pin[GPIO_NUM_MAX];  //pin number of gpio
.
251d
242,249d
235d
224c
    /*.buz_on_ms                      =*/ 0,  // buzzer on duration in ms
.
207,208c
                                            UUID_CHARACTERISTIC_TX_POWER_LEVEL}, // GATT characteristic UUID
.
204,205c
                                            UUID_SERVICE_TX_POWER}, // GATT service UUID
.
201c
    /*.powersave_timeout              =*/ 0,    // second  0-> no timeout
.
193c
    /*.local_name                     =*/ "ChairLeave", // [LOCAL_NAME_LEN_MAX];
.
124,175d
97,98c
    CHARACTERISTIC_UUID16 (0x0015, 0x0016, UUID_CHARACTERISTIC_DEVICE_NAME, LEGATTDB_CHAR_PROP_READ, LEGATTDB_PERM_READABLE, 10),
        'C','h','a','i','r','L','e','a','v','e',
.
81a
void chairleave_pollChairLeave(void);
void chairleave_onLeave(void);

.
59a
void chairleave_Create(void);
UINT32 chairleave_ProxButton(UINT32 function);
.
56d
54c
#define SENSOR_LED_PIN GPIO_PIN_P24 // koshian PIO5
.
52a
#include "gpiodriver.h"
#define USE_ADC 1
#if USE_ADC
# include "adc.h"
# define SENSOR_PIN GPIO_PIN_P14 // koshian AIO0
# define SENSOR_THRESHOLD 900 // [mV]
#else
# define SW_PIN GPIO_PIN_P14
#endif
.
x

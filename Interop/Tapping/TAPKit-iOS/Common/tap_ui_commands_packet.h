/*
* strap_tap_data_packet.h
*
*  Created on: Oct 3, 2017
*      Author: Me
*/

#ifndef TAP_UI_COMMANDS_PACKET_H
#define TAP_UI_COMMANDS_PACKET_H

#ifdef __cplusplus
extern "C"
{
#endif

	/*********************************************************************
	* INCLUDES
	*/
#include <inttypes.h>
#include "compiler_helper.h"

	/*********************************************************************
	* CONSTANTS
	*/
#define TAP_UI_COMMAND_PACKET_SIZE	(20)

	/*********************************************************************
	* TYPEDEFS
	*/



	PACKED_STRUCT_TYPEDEF_BEGIN(tap_ui_command_periph_haptic_action_trigger_t) {
		uint16_t duration_ms; // Accepted range is [1, 300]
		uint8_t power_level; // Accepted range is [1, 100]
	} PACKED_STRUCT_TYPEDEF_END(tap_ui_command_periph_haptic_action_trigger_t);



	typedef enum {
		TAP_UI_COMMAND_PERIPH_HAPTIC_ACTION_TRIGGER = 0,
		TAP_UI_COMMAND_PERIPH_HAPTIC_ACTIONS_COUNT
	} tap_ui_command_periph_haptic_actions_t;

	PACKED_STRUCT_TYPEDEF_BEGIN(tap_ui_command_periph_haptic_t) {
		uint8_t action_type; //Use type tap_ui_command_periph_haptic_actions_t
		union {
			tap_ui_command_periph_haptic_action_trigger_t trigger;
		} action;
	} PACKED_STRUCT_TYPEDEF_END(tap_ui_command_periph_haptic_t);




	typedef enum {
		TAP_UI_COMMANDS_PERIPH_TYPE_HAPTIC = 0,
		TAP_UI_COMMANDS_PERIPH_TYPE_LED = 1,
		TAP_UI_COMMANDS_PERIPH_TYPE_BUTTON = 2,
		TAP_UI_COMMANDS_PERIPH_TYPES_COUNT
	} tap_ui_commands_periph_types_t;

	PACKED_STRUCT_TYPEDEF_BEGIN(tap_ui_command_parsed_packet_t) {
		uint8_t peripheral_type; // Use type tap_ui_commands_periph_types_t
		union {
			tap_ui_command_periph_haptic_t haptic;
		} peripheral;
	} PACKED_STRUCT_TYPEDEF_END(tap_ui_command_parsed_packet_t);





	typedef union {
		uint8_t 						raw_packet[TAP_UI_COMMAND_PACKET_SIZE];
		tap_ui_command_parsed_packet_t 	parsed_packet;
	} tap_ui_commands_metapacket_t;

	/*********************************************************************
	* PUBLIC FUNCTIONS
	*/

#ifdef __cplusplus
}
#endif

#endif /* TAP_UI_COMMANDS_PACKET_H */

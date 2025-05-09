/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include <defs.h>
#include <stub.c>

void main()
{
    // Coefficients and input signal
    int taps[11] = {0, -10, -9, 23, 56, 63, 56, 23, -9, -10, 0};
    int inputsignal[11] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

    // Configure GPIO pins
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

    reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_9  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_8  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_7  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_5  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_4  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_3  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_2  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_1  = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_0  = GPIO_MODE_USER_STD_OUTPUT;

    reg_mprj_io_6  = GPIO_MODE_MGMT_STD_OUTPUT;

    // Enable UART
    reg_uart_enable = 1;

    // Apply configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // Configure LA probes
    reg_la0_oenb = reg_la0_iena = 0x00000000; // [31:0] inputs
    reg_la1_oenb = reg_la1_iena = 0xFFFFFFFF; // [63:32] outputs
    reg_la2_oenb = reg_la2_iena = 0x00000000; // [95:64] inputs
    reg_la3_oenb = reg_la3_iena = 0x00000000; // [127:96] inputs

    // Flag test start
    reg_mprj_datal = 0xAB400000;

    // Load coefficients via Wishbone (base address 0x30000000)
    for (int i = 0; i < 11; i++) {
        reg_mprj_datah = (i << 8) | 0x00; // Address: index in [19:8]
        reg_mprj_datal = taps[i];         // Data
        reg_wb_enable = 1;
        while (reg_wb_ack == 0);
        reg_wb_enable = 0;
    }

    // Feed input signals via LA and read outputs
    for (int i = 0; i < 11; i++) {
        // Set input sample
        reg_la1_data = (1ULL << 64) | inputsignal[i]; // Valid bit and data
        while (!(reg_la0_data_in & 0x80000000));      // Wait for ready_o
        reg_mprj_datal = reg_la0_data_in << 16;       // Output to mprj_io[31:16]
        reg_la1_data = 0;                             // Clear valid
    }

    // Flag test end
    reg_mprj_datal = 0xAB510000;
}
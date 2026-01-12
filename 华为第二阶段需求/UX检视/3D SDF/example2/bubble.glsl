// ---------------- scene toggles ----------------
const float EPS_SURF   = 1e-4;
const int   SAMPLE_N   = 256;
const int   BISECT_ITR = 12;
const float TMAX       = 15.0; // 模版设定：最大距离 15.0

// ---------------- helpers ----------------
mat3 rotX(float a){ float c=cos(a), s=sin(a); return mat3(1,0,0, 0,c,-s, 0,s,c); }
mat3 rotY(float a){ float c=cos(a), s=sin(a); return mat3(c,0,s, 0,1,0, -s,0,c); }
mat3 rotZ(float a){ float c=cos(a), s=sin(a); return mat3(c,-s,0, s,c,0, 0,0,1); }

// ---------------- params (你的新数据 NUM_SQ = 61) ----------------
const int NUM_SQ = 61;
void getSQ(int i, out float params[11])
{
    if (i == 0) {
        const float tmp[11] = float[11](
            8.8688e-01, 1.1495e+00, 1.1737e-01,
            1.1727e-01, 1.1217e-01, 9.8032e-02,
            -7.8741e-01, -1.5915e+00, -1.2378e+00,
            6.0046e-02, 3.3675e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 1) {
        const float tmp[11] = float[11](
            1.2845e+00, 1.1690e+00, 5.6893e-02,
            8.2432e-02, 1.4087e-01, 1.1486e-02,
            -2.8270e-03, -9.8147e-02, -1.2567e+00,
            3.3343e-01, -7.8200e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 2) {
        const float tmp[11] = float[11](
            8.8154e-01, 1.1134e+00, 4.5174e-02,
            4.5716e-02, 4.2920e-02, 1.5971e+00,
            -7.4948e-01, 1.5872e+00, -1.2921e+00,
            1.4265e-01, -8.8744e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 3) {
        const float tmp[11] = float[11](
            8.8671e-01, 8.9307e-01, 1.0302e-01,
            1.0344e-01, 1.0293e-01, 1.4039e-02,
            1.1898e-01, 3.2383e-05, -1.2192e+00,
            -4.3590e-01, -1.2348e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 4) {
        const float tmp[11] = float[11](
            8.9191e-01, 8.8602e-01, 7.5299e-02,
            7.4387e-02, 7.4388e-02, 1.5933e+00,
            4.0051e-04, 1.3424e+00, -1.1915e+00,
            -4.8361e-01, 1.3165e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 5) {
        const float tmp[11] = float[11](
            9.0950e-01, 8.4681e-01, 1.1846e-01,
            1.0352e-01, 1.2292e-01, 2.0765e-02,
            1.3854e-03, 4.9735e-03, -1.2616e+00,
            3.0602e-01, 3.6137e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 6) {
        const float tmp[11] = float[11](
            7.2903e-01, 9.0462e-01, 6.3838e-02,
            8.3814e-02, 7.6093e-02, 1.8218e+00,
            1.4557e-02, -1.5589e-02, -1.1991e+00,
            -7.2192e-01, -1.1557e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 7) {
        const float tmp[11] = float[11](
            5.2905e-01, 1.2660e+00, 7.2713e-02,
            5.6041e-02, 1.2320e-01, -2.9068e+00,
            -9.0143e-01, 1.0083e+00, -1.1913e+00,
            -1.5346e-01, -8.8871e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 8) {
        const float tmp[11] = float[11](
            9.8165e-01, 1.1171e+00, 8.9758e-02,
            9.0317e-02, 9.1822e-02, -2.9359e-01,
            -9.5865e-01, -1.4363e+00, -1.1609e+00,
            -2.6795e-01, 1.0853e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 9) {
        const float tmp[11] = float[11](
            5.4660e-01, 3.3048e-01, 6.1758e-02,
            6.1051e-02, 7.3991e-02, 9.6220e-03,
            2.1378e-02, 1.1667e-03, -1.1937e+00,
            -7.2476e-01, 1.2191e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 10) {
        const float tmp[11] = float[11](
            8.8064e-01, 8.8098e-01, 1.2366e-01,
            1.2343e-01, 1.2406e-01, 2.3328e-02,
            -1.9162e-02, -1.9174e-05, -1.2611e+00,
            2.8769e-01, 3.3740e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 11) {
        const float tmp[11] = float[11](
            9.2680e-01, 9.1389e-01, 7.6705e-02,
            8.8175e-02, 8.2004e-02, 1.2830e-09,
            4.2770e-09, -1.7657e-09, -1.2438e+00,
            6.0943e-01, -3.3670e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 12) {
        const float tmp[11] = float[11](
            1.1013e+00, 1.1061e+00, 1.0302e-01,
            1.0212e-01, 1.0632e-01, 6.8886e-01,
            -3.2887e-01, 2.1911e-01, -1.2731e+00,
            3.2689e-01, -3.9973e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 13) {
        const float tmp[11] = float[11](
            6.0452e-01, 8.1667e-01, 3.3676e-02,
            4.1771e-02, 9.7103e-02, 1.1328e-01,
            -9.8902e-02, 8.6090e-01, -1.2655e+00,
            3.2505e-01, 4.3051e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 14) {
        const float tmp[11] = float[11](
            8.8844e-01, 1.1669e+00, 8.0121e-02,
            8.0057e-02, 7.8526e-02, -2.1882e-02,
            -3.8591e-01, -1.5722e+00, -1.2212e+00,
            -5.9214e-01, -1.2523e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 15) {
        const float tmp[11] = float[11](
            8.8656e-01, 8.8167e-01, 8.7122e-02,
            8.7217e-02, 8.8682e-02, 2.5658e+00,
            1.4347e+00, 9.2279e-01, -1.2090e+00,
            -8.8278e-02, -8.9024e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 16) {
        const float tmp[11] = float[11](
            8.7493e-01, 1.1747e+00, 7.4098e-02,
            7.3480e-02, 6.9097e-02, 2.3214e+00,
            -2.0147e-01, 3.9299e-02, -1.1635e+00,
            -1.3723e-01, 8.6847e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 17) {
        const float tmp[11] = float[11](
            2.4928e-01, 7.6269e-01, 1.0407e-01,
            7.5867e-02, 4.9407e-02, 7.8938e-04,
            -5.8109e-02, 1.5698e+00, -1.1776e+00,
            -7.3546e-01, 1.2623e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 18) {
        const float tmp[11] = float[11](
            8.9775e-01, 8.7374e-01, 7.4126e-02,
            7.4174e-02, 7.6779e-02, 9.7698e-03,
            -1.6168e-01, -1.5717e+00, -1.2160e+00,
            -6.0412e-01, 1.0775e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 19) {
        const float tmp[11] = float[11](
            8.3587e-01, 7.9126e-01, 6.4139e-02,
            7.6074e-02, 6.4457e-02, 1.3389e-01,
            3.2563e+00, 1.7881e-03, -1.1690e+00,
            -2.8800e-01, -9.5371e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 20) {
        const float tmp[11] = float[11](
            8.5147e-02, 6.6438e-01, 8.4289e-02,
            1.2716e-01, 3.6332e-02, 6.7623e-03,
            -1.4105e+00, -1.5769e+00, -1.1386e+00,
            -7.4789e-01, -1.3067e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 21) {
        const float tmp[11] = float[11](
            8.5664e-02, 6.6438e-01, 8.4294e-02,
            1.2713e-01, 3.6336e-02, -3.1351e+00,
            -1.4105e+00, 1.5650e+00, -1.1386e+00,
            -7.4789e-01, 1.3741e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 22) {
        const float tmp[11] = float[11](
            8.7067e-01, 1.1610e+00, 6.8983e-02,
            6.9114e-02, 6.7109e-02, -5.2444e-03,
            -7.1819e-01, -1.5486e+00, -1.1561e+00,
            -3.7598e-01, 9.5007e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 23) {
        const float tmp[11] = float[11](
            1.0230e+00, 9.4818e-01, 1.2323e-01,
            1.5475e-01, 1.6883e-01, 3.3438e+00,
            3.5140e-05, 1.5561e+00, -1.2413e+00,
            6.1772e-01, 3.4496e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 24) {
        const float tmp[11] = float[11](
            8.8234e-01, 8.9891e-01, 8.4305e-02,
            8.3311e-02, 8.3128e-02, -1.5260e+00,
            -1.4388e+00, 1.9748e-02, -1.2539e+00,
            3.1103e-01, 2.9413e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 25) {
        const float tmp[11] = float[11](
            8.8464e-01, 8.9036e-01, 7.6013e-02,
            7.6579e-02, 7.6771e-02, -1.5103e+00,
            -1.3318e+00, -5.9114e-02, -1.2734e+00,
            3.4931e-01, -1.6792e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 26) {
        const float tmp[11] = float[11](
            1.3433e+00, 7.3329e-01, 7.1016e-02,
            4.5394e-02, 1.0678e-01, 4.2879e-02,
            1.1868e-01, 1.1766e-01, -1.2571e+00,
            3.2076e-01, -6.4260e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 27) {
        const float tmp[11] = float[11](
            4.0343e-01, 7.2147e-01, 6.3996e-02,
            4.6112e-02, 1.0533e-01, 3.1962e-03,
            2.3481e-02, -1.1963e-01, -1.2583e+00,
            3.1487e-01, 5.9624e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 28) {
        const float tmp[11] = float[11](
            8.9989e-01, 1.1482e+00, 5.5189e-02,
            5.6278e-02, 5.2853e-02, 7.7880e-01,
            1.7078e-02, 1.7873e-01, -1.2409e+00,
            -4.9430e-02, 9.7334e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 29) {
        const float tmp[11] = float[11](
            8.9090e-01, 1.1579e+00, 5.2685e-02,
            5.2298e-02, 5.0332e-02, 2.3549e+00,
            8.4115e-02, -3.0218e+00, -1.2102e+00,
            1.8789e-01, 9.6623e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 30) {
        const float tmp[11] = float[11](
            1.1577e+00, 1.2403e+00, 8.1030e-02,
            1.1094e-01, 8.0317e-02, 1.2578e-01,
            -6.6338e-01, 2.2118e-02, -1.1850e+00,
            -2.2041e-01, -9.5301e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 31) {
        const float tmp[11] = float[11](
            8.4725e-01, 8.6491e-01, 3.8470e-02,
            5.5166e-02, 3.8266e-02, -1.2572e-01,
            -1.1399e+00, -1.8113e+00, -1.1754e+00,
            2.3052e-01, -5.7360e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 32) {
        const float tmp[11] = float[11](
            9.6349e-01, 8.6440e-01, 3.6966e-02,
            3.5789e-02, 4.0327e-02, 1.5660e+00,
            6.6772e-02, 2.2795e+00, -1.1399e+00,
            -1.4526e-01, -1.5064e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 33) {
        const float tmp[11] = float[11](
            7.5185e-01, 5.8458e-01, 8.2711e-02,
            1.3254e-01, 5.3016e-02, 1.6637e-01,
            -1.3882e+00, -1.7617e+00, -1.1443e+00,
            -7.3402e-01, -1.2799e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 34) {
        const float tmp[11] = float[11](
            7.5972e-01, 7.9917e-01, 1.0500e-01,
            5.2502e-02, 8.4557e-02, -6.4078e-02,
            -2.3434e-01, 3.3928e-02, -1.1143e+00,
            -7.3455e-01, 1.3955e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 35) {
        const float tmp[11] = float[11](
            8.6000e-01, 8.6379e-01, 5.9769e-02,
            6.1783e-02, 6.1897e-02, 1.5759e-02,
            -7.1243e-02, 1.3238e-01, -1.2970e+00,
            3.5206e-01, 4.0066e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 36) {
        const float tmp[11] = float[11](
            1.1911e+00, 8.7128e-01, 6.9864e-02,
            6.9980e-02, 9.6191e-02, 3.1385e+00,
            9.8012e-02, -1.4726e-02, -1.2713e+00,
            3.1875e-01, -5.3017e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 37) {
        const float tmp[11] = float[11](
            8.9665e-01, 1.1596e+00, 7.5759e-02,
            7.5725e-02, 7.4519e-02, 2.3898e+00,
            1.5776e-01, 8.5175e-02, -1.2699e+00,
            3.4266e-01, 1.6507e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 38) {
        const float tmp[11] = float[11](
            8.8420e-01, 1.1571e+00, 7.5485e-02,
            7.5493e-02, 7.3544e-02, 8.0497e-01,
            -1.4687e-01, 6.7486e-02, -1.2615e+00,
            3.2069e-01, 5.5965e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 39) {
        const float tmp[11] = float[11](
            4.9603e-01, 2.0000e+00, 3.4128e-02,
            1.1596e-01, 6.0981e-02, 1.5721e+00,
            3.9912e-02, 1.5733e+00, -1.2478e+00,
            3.2628e-01, -6.8822e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 40) {
        const float tmp[11] = float[11](
            7.7996e-01, 1.0547e+00, 4.1403e-02,
            7.4680e-02, 7.8294e-02, 1.5209e+00,
            2.7818e-01, 1.3646e+00, -1.2509e+00,
            3.1806e-01, 6.6242e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 41) {
        const float tmp[11] = float[11](
            8.7233e-01, 1.1591e+00, 6.1382e-02,
            6.2738e-02, 5.8450e-02, -1.5179e+00,
            -7.1207e-01, -1.8891e+00, -1.2648e+00,
            2.9286e-01, -2.6589e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 42) {
        const float tmp[11] = float[11](
            8.7638e-01, 1.0075e+00, 6.4837e-02,
            8.3381e-02, 6.3900e-02, -7.1040e-01,
            1.5709e+00, -5.7218e-01, -1.2412e+00,
            4.4564e-01, 3.3676e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 43) {
        const float tmp[11] = float[11](
            8.8420e-01, 1.1571e+00, 7.5493e-02,
            7.5485e-02, 7.3544e-02, 2.3857e+00,
            -6.6757e-02, 2.9944e+00, -1.2615e+00,
            3.2069e-01, 5.5965e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 44) {
        const float tmp[11] = float[11](
            8.6756e-01, 1.1298e+00, 5.7108e-02,
            5.7667e-02, 5.5224e-02, 8.0517e-01,
            -1.1248e-01, 2.2364e-02, -1.2431e+00,
            2.9243e-01, 4.6454e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 45) {
        const float tmp[11] = float[11](
            9.0330e-01, 9.1245e-01, 3.4459e-02,
            3.7992e-02, 3.4165e-02, 1.3874e-01,
            -3.2432e-02, -2.9207e-01, -1.1721e+00,
            -5.8817e-02, 4.9429e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 46) {
        const float tmp[11] = float[11](
            5.1194e-01, 9.1882e-01, 1.6822e-02,
            1.9341e-02, 7.9334e-02, -1.0306e-01,
            -5.0644e-02, -2.5759e-02, -1.3128e+00,
            3.2347e-01, -6.9850e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 47) {
        const float tmp[11] = float[11](
            3.6412e-01, 9.1821e-01, 2.0183e-02,
            7.0453e-02, 3.6836e-02, 1.5863e+00,
            -3.8325e-03, 1.5706e+00, -1.2583e+00,
            3.2361e-01, 7.3609e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 48) {
        const float tmp[11] = float[11](
            1.4108e+00, 7.8301e-01, 4.3768e-02,
            4.9347e-02, 9.5766e-02, 6.6460e-01,
            -3.5778e-01, -1.0336e+00, -1.2221e+00,
            3.1561e-01, -6.4329e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 49) {
        const float tmp[11] = float[11](
            1.0209e+00, 1.6592e+00, 5.8571e-02,
            8.5623e-02, 4.1080e-02, -1.7387e+00,
            9.4132e-01, 7.4276e-01, -1.2173e+00,
            3.1492e-01, 6.5499e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 50) {
        const float tmp[11] = float[11](
            5.2121e-01, 9.5188e-01, 1.7020e-02,
            1.9600e-02, 7.9530e-02, -3.2799e+00,
            -5.0990e-02, -2.8910e-02, -1.3128e+00,
            3.2368e-01, 7.0508e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 51) {
        const float tmp[11] = float[11](
            5.9026e-01, 8.3308e-01, 2.1227e-02,
            2.1463e-02, 8.6687e-02, 5.3422e-01,
            -1.8119e-01, -4.8993e-03, -1.2062e+00,
            3.2716e-01, 7.1639e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 52) {
        const float tmp[11] = float[11](
            1.0443e+00, 8.2978e-01, 2.4906e-02,
            2.4517e-02, 7.5450e-02, 2.5036e-01,
            -1.2556e-01, 2.4189e+00, -1.1853e+00,
            2.8656e-01, -6.6318e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 53) {
        const float tmp[11] = float[11](
            1.0819e+00, 8.0661e-01, 2.5062e-02,
            2.4857e-02, 7.7257e-02, 2.4521e-01,
            1.3995e-01, 7.2806e-01, -1.1859e+00,
            2.8743e-01, 6.6922e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 54) {
        const float tmp[11] = float[11](
            1.3107e+00, 1.6387e+00, 5.1588e-02,
            1.2704e-01, 8.2660e-02, 1.9920e-01,
            -7.6044e-01, -1.1968e-01, -1.2981e+00,
            6.0751e-01, -8.4608e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 55) {
        const float tmp[11] = float[11](
            1.5053e+00, 1.3879e+00, 8.4282e-02,
            5.0593e-02, 1.2526e-01, 3.4446e-03,
            -8.2085e-01, -1.4298e+00, -1.2989e+00,
            6.0813e-01, 9.0924e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 56) {
        const float tmp[11] = float[11](
            7.7477e-02, 7.8415e-01, 8.3775e-02,
            1.3619e-01, 3.0977e-02, 1.4100e-02,
            -1.4560e+00, -1.5852e+00, -1.1442e+00,
            -7.5324e-01, -1.2859e-01
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 57) {
        const float tmp[11] = float[11](
            9.8035e-01, 1.2096e+00, 1.3204e-01,
            1.5939e-01, 1.1673e-01, 2.6524e+00,
            -4.1853e+00, 2.2916e+00, -1.2404e+00,
            6.0026e-01, -2.3004e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 58) {
        const float tmp[11] = float[11](
            1.3049e+00, 1.3729e+00, 7.4688e-02,
            1.1268e-01, 1.3569e-01, -7.6533e-02,
            -6.7901e-01, -1.3693e+00, -1.1998e+00,
            5.9757e-01, 7.2214e-02
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 59) {
        const float tmp[11] = float[11](
            1.7095e+00, 1.2776e+00, 3.0278e-02,
            7.9300e-02, 9.9087e-02, -3.5791e-02,
            1.7176e-03, -1.8667e-03, -1.1375e+00,
            5.8004e-01, 3.0391e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else if (i == 60) {
        const float tmp[11] = float[11](
            7.6837e-01, 1.8407e+00, 1.1111e-01,
            3.6017e-02, 9.5759e-02, -9.4871e-02,
            -1.5708e+00, -1.6741e+00, -1.3341e+00,
            6.6107e-01, 3.4006e-03
        );
        for (int k = 0; k < 11; ++k) params[k] = tmp[k];
    }
    else {
        for (int k = 0; k < 11; ++k) params[k] = 0.0;
    }
}
// <<< --------------------------- >>>

// ---------------- implicit: G(p) = F(p)-1 ----------------
float G_local(vec3 X, float e1, float e2, vec3 a){
    e1 = max(e1,1e-6);
    e2 = max(e2,1e-6);
    float invE1 = 1.0/e1, invE2 = 1.0/e2;

    vec3 q = abs(X) / max(a, vec3(1e-6));
    q = clamp(q, 1e-12, 3.0);

    float x = pow(q.x, 2.0*invE2);
    float y = pow(q.y, 2.0*invE2);
    float z = pow(q.z, 2.0*invE1);

    float base = min(x + y, 1e6);
    float xy   = pow(base, e2*invE1);

    return xy + z - 1.0;
}
float G_world(vec3 p, const float prm[11]){
    float e1=prm[0], e2=prm[1];
    vec3  a = vec3(prm[2],prm[3],prm[4]);
    vec3  ang=vec3(prm[5],prm[6],prm[7]); // z,y,x
    vec3  t  = vec3(prm[8],prm[9],prm[10]);

    mat3 R = rotZ(ang.x) * rotY(ang.y) * rotX(ang.z);
    vec3 X = transpose(R) * (p - t);      // world -> local
    return G_local(X, e1, e2, a);
}

// ---------------- ray-sphere bound per object ----------------
bool raySphere(vec3 ro, vec3 rd, vec3 c, float r, out float t0, out float t1){
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float c2= dot(oc, oc) - r*r;
    float D = b*b - c2;
    if(D < 0.0) return false;
    float s = sqrt(D);
    t0 = -b - s; t1 = -b + s;
    return t1 >= 0.0;
}

// ---------------- root finder (二分查找) ----------------
bool intersectSuper(vec3 ro, vec3 rd, const float prm[11], out float tHit){
    vec3 center = vec3(prm[8],prm[9],prm[10]);
    float rBound = max(prm[2], max(prm[3], prm[4])) * 1.05 * sqrt(3.0);

    float t0, t1;
    if(!raySphere(ro, rd, center, rBound, t0, t1)) return false;
    t0 = max(0.0, t0);
    t1 = min(t1, TMAX);
    if(t0 >= t1) return false;

    float prevT = t0;
    float prevG = G_world(ro + rd*t0, prm);
    bool found = false;
    float ta = t0, tb = t1;

    for(int i=1;i<=SAMPLE_N;i++){
        float t = mix(t0, t1, float(i)/float(SAMPLE_N));
        float Gt = G_world(ro + rd*t, prm);
        if(Gt == 0.0){ ta=tb=t; found=true; break; }
        if(prevG > 0.0 && Gt < 0.0){ ta = prevT; tb = t; found=true; break; }
        prevT = t; prevG = Gt;
    }
    if(!found) return false;

    float aT = ta, bT = tb;
    float Ga = G_world(ro + rd*aT, prm);
    float Gb = G_world(ro + rd*bT, prm);
    if(Ga*Gb > 0.0){
        float dt = (tb-ta)*0.1 + 1e-3;
        aT = max(t0, tb - dt); bT = min(t1, tb + dt);
        Ga = G_world(ro + rd*aT, prm);
        Gb = G_world(ro + rd*bT, prm);
        if(Ga*Gb > 0.0) return false;
    }
    for(int k=0;k<BISECT_ITR;k++){
        float m = 0.5*(aT+bT);
        float Gm = G_world(ro + rd*m, prm);
        if(abs(Gm) < 1e-6 || abs(bT-aT) < EPS_SURF){ aT=bT=m; break; }
        if(Ga*Gm <= 0.0){ bT=m; Gb=Gm; } else { aT=m; Ga=Gm; }
    }
    tHit = 0.5*(aT+bT);
    return tHit>=0.0 && tHit<=TMAX;
}

// ---------------- normal via finite difference ----------------
vec3 normalAt(vec3 p, const float prm[11], float t){
    float h = clamp(0.0005*(1.0+0.2*t), 5e-5, 2e-3);
    vec3 e = vec3(h,0,0);
    float gx = G_world(p+e.xyy, prm) - G_world(p-e.xyy, prm);
    float gy = G_world(p+e.yxy, prm) - G_world(p-e.yxy, prm);
    float gz = G_world(p+e.yyx, prm) - G_world(p-e.yyx, prm);
    return normalize(vec3(gx,gy,gz));
}

// ---------------- shading (模版：白色) ----------------
vec3 shade(vec3 pos, vec3 n, vec3 v){
    // 模版光照位置
    vec3 lightPos  = vec3(-2.0, 4.0, 3.0);
    
    vec3 l = normalize(lightPos - pos);
    float ndl = max(dot(n,l),0.0);
    vec3 h = normalize(l+v);
    
    // 模版高光
    float spec = pow(max(dot(n,h),0.0), 32.0);
    
    // 模版颜色：白色
    vec3 base = vec3(0.95);
    
    return base*(0.3 + 0.7*ndl) + 0.4*spec;
}

// ---------------- main ----------------
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // 1. 计算所有 SQ 的几何中心
    vec3 sumPos = vec3(0.0);
    float validCount = 0.0;

    for(int i = 0; i < NUM_SQ; i++) {
        float prm[11]; 
        getSQ(i, prm);
        if(prm[2] > 0.001) { 
            vec3 t = vec3(prm[8], prm[9], prm[10]);
            sumPos += t;
            validCount += 1.0;
        }
    }
    vec3 center = (validCount > 0.0) ? (sumPos / validCount) : vec3(0.0);

    // 2. 相机设置 (应用模版)
    const float FOVY = radians(45.0);
    vec3 TARGET = center; 
    
    // [模版]：相机拉远
    float dist = (1.2 / tan(0.5 * FOVY)) * 5.0; 

    // [模版]：角度陡峭俯视
    vec3 camDir = normalize(vec3(8.0, 0, 1.0)); 
    
    vec3 camPos = TARGET + camDir * dist;
    vec3 UP     = vec3(0.0, 1.0, 0.0);

    vec3 fw = normalize(TARGET - camPos);
    vec3 rt = normalize(cross(fw, UP));
    vec3 up = cross(rt, fw);

    vec2 q = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rd = normalize(q.x * rt + q.y * up + (1.0 / tan(0.5 * FOVY)) * fw);

    // 3. 渲染循环
    float bestT = 1e9;
    int   bestI = -1;

    for(int i=0;i<NUM_SQ;i++){
        float prm[11]; getSQ(i,prm);
        float tHit;
        if(intersectSuper(camPos, rd, prm, tHit)){
            if(tHit < bestT){ bestT = tHit; bestI = i; }
        }
    }

    vec3 col;
    if(bestI >= 0){
        float prm[11]; getSQ(bestI, prm);
        vec3 pos = camPos + rd*bestT;
        vec3 n   = normalAt(pos, prm, bestT);
        vec3 v   = normalize(camPos - pos);
        
        col = shade(pos, n, v);
    }else{
        // [模版]：背景颜色蓝白渐变
        float t = smoothstep(-0.5, 0.5, q.y);

        vec3 topColor = vec3(71.0/255.0, 170.0/255.0, 255.0/255.0);
        // 底部白色
        vec3 bottomColor = vec3(1.0);
        
        col = mix(bottomColor, topColor, t);
    }

    col = pow(col, vec3(0.4545)); 
    fragColor = vec4(col,1.0);
}
# STM32 Deployment

After every CubeMX “Generate Code”, run:

```bash
./platform/stm32/patch_cubemx.sh platform/stm32/<board>
```
Example:

```bash
./platform/stm32/patch_cubemx.sh platform/stm32/nucleo_h7a3ziq
```

Never edit files under `<board>/`  manually except via this patch.

This fixes CubeMX-generated cmake/stm32cubemx/CMakeLists.txt so it works even when the CubeMX project is nested inside a higher level application repository.

---
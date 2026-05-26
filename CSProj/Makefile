MSBUILD:=msbuild

debug:
	$(MSBUILD) BetterSkybox.csproj /p:Configuration=Debug /p:Platform=x64
	cp obj/x64/Debug/BetterSkybox.dll .

release:
	$(MSBUILD) BetterSkybox.csproj /p:Configuration=Release /p:Platform=x64
	cp obj/x64/Release/BetterSkybox.dll .

clean:
	rm -f BetterSkybox.dll
	rm -rf obj

.PHONY: release

{ gcpt }: gcpt.overrideAttrs (old: {
  passthru = { inherit gcpt; };
})

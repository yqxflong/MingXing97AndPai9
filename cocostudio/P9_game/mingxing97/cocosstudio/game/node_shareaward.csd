<GameFile>
  <PropertyGroup Name="node_shareaward" Type="Node" ID="ec95e05a-07f3-4022-a0b0-1796717e3318" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="10" Speed="1.0000">
        <Timeline ActionTag="926780143" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="game/g_roll_light1.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="game/g_roll_light2.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="game/g_roll_light1.png" Plist="" />
          </TextureFrame>
        </Timeline>
      </Animation>
      <ObjectData Name="Node" Tag="33" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="panel_mask" ActionTag="289710819" Tag="225" IconVisible="False" LeftMargin="-375.0000" RightMargin="-375.0000" TopMargin="-668.9997" BottomMargin="-665.0003" TouchEnable="True" ClipAble="False" BackColorAlpha="0" ComboBoxIndex="1" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
            <Size X="750.0000" Y="1334.0000" />
            <AnchorPoint />
            <Position X="-375.0000" Y="-665.0003" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <SingleColor A="255" R="0" G="0" B="0" />
            <FirstColor A="255" R="150" G="200" B="255" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="img_light" ActionTag="926780143" Tag="101" IconVisible="False" LeftMargin="-294.2903" RightMargin="-285.7097" TopMargin="-18.2570" BottomMargin="-561.7429" ctype="SpriteObjectData">
            <Size X="580.0000" Y="580.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-4.2903" Y="-271.7430" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="game/g_roll_light1.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="img_roll" ActionTag="-1660945267" Tag="35" IconVisible="False" LeftMargin="-295.0537" RightMargin="-284.9463" TopMargin="16.7996" BottomMargin="-596.7996" ctype="SpriteObjectData">
            <Size X="580.0000" Y="580.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-5.0537" Y="-306.7996" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="game/g_roll.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="img_title" ActionTag="-55417822" Tag="34" IconVisible="False" LeftMargin="-192.4960" RightMargin="-192.5040" TopMargin="67.5622" BottomMargin="-205.5622" ctype="SpriteObjectData">
            <Size X="385.0000" Y="138.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="0.0040" Y="-136.5622" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="game/g_sharetitle.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="btn_close" ActionTag="-28659656" Tag="36" IconVisible="False" LeftMargin="199.2347" RightMargin="-279.2347" TopMargin="70.9827" BottomMargin="-150.9827" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="50" Scale9Height="58" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="80.0000" Y="80.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="239.2347" Y="-110.9827" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Normal" Path="game/g_close3.png" Plist="" />
            <PressedFileData Type="Normal" Path="game/g_close2.png" Plist="" />
            <NormalFileData Type="Normal" Path="game/g_close1.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="btn_moment" ActionTag="-622986667" Tag="37" IconVisible="False" LeftMargin="-103.0892" RightMargin="-99.9108" TopMargin="485.0338" BottomMargin="-576.0338" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="173" Scale9Height="69" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="203.0000" Y="91.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-1.5892" Y="-530.5338" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Normal" Path="game/g_moment3.png" Plist="" />
            <PressedFileData Type="Normal" Path="game/g_moment2.png" Plist="" />
            <NormalFileData Type="Normal" Path="game/g_moment1.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="atlas_num_1" ActionTag="650266460" Tag="38" IconVisible="False" LeftMargin="-231.5018" RightMargin="169.5018" TopMargin="325.3461" BottomMargin="-407.3461" CharWidth="62" CharHeight="82" LabelText="0" StartChar="0" ctype="TextAtlasObjectData">
            <Size X="62.0000" Y="82.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-200.5018" Y="-366.3461" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <LabelAtlasFileImage_CNB Type="Normal" Path="game/atlas_num.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="atlas_num_2" ActionTag="-410034498" Tag="39" IconVisible="False" LeftMargin="-152.9140" RightMargin="90.9140" TopMargin="325.2137" BottomMargin="-407.2137" CharWidth="62" CharHeight="82" LabelText="0" StartChar="0" ctype="TextAtlasObjectData">
            <Size X="62.0000" Y="82.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-121.9140" Y="-366.2137" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <LabelAtlasFileImage_CNB Type="Normal" Path="game/atlas_num.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="atlas_num_3" ActionTag="-181458455" Tag="40" IconVisible="False" LeftMargin="-74.3215" RightMargin="12.3215" TopMargin="325.0811" BottomMargin="-407.0811" CharWidth="62" CharHeight="82" LabelText="0" StartChar="0" ctype="TextAtlasObjectData">
            <Size X="62.0000" Y="82.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-43.3215" Y="-366.0811" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <LabelAtlasFileImage_CNB Type="Normal" Path="game/atlas_num.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="atlas_num_4" ActionTag="-1402426282" Tag="41" IconVisible="False" LeftMargin="3.4849" RightMargin="-65.4849" TopMargin="324.9484" BottomMargin="-406.9484" CharWidth="62" CharHeight="82" LabelText="0" StartChar="0" ctype="TextAtlasObjectData">
            <Size X="62.0000" Y="82.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="34.4849" Y="-365.9484" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <LabelAtlasFileImage_CNB Type="Normal" Path="game/atlas_num.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="atlas_num_5" ActionTag="1571562117" Tag="42" IconVisible="False" LeftMargin="82.8546" RightMargin="-144.8546" TopMargin="326.3745" BottomMargin="-408.3745" CharWidth="62" CharHeight="82" LabelText="0" StartChar="0" ctype="TextAtlasObjectData">
            <Size X="62.0000" Y="82.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="113.8546" Y="-367.3745" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <LabelAtlasFileImage_CNB Type="Normal" Path="game/atlas_num.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="atlas_num_6" ActionTag="-2062027981" Tag="43" IconVisible="False" LeftMargin="159.8855" RightMargin="-221.8855" TopMargin="324.6832" BottomMargin="-406.6832" CharWidth="62" CharHeight="82" LabelText="0" StartChar="0" ctype="TextAtlasObjectData">
            <Size X="62.0000" Y="82.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="190.8855" Y="-365.6832" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <LabelAtlasFileImage_CNB Type="Normal" Path="game/atlas_num.png" Plist="" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>
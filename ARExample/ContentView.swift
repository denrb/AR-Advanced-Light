//
//  ContentView.swift
//  ARExample
//
//  Created by Den on 2020-10-21.
//

import SwiftUI
import RealityKit
import Darwin

struct ContentView : View {
    
    let model = Model()
    
    @State private var offset: Float = 0
    
    @State private var hidePlane: Bool = false
    
    let timer = Timer.publish(every: 3.0 / 90.0, on: .current, in: .common)
                     .autoconnect()
    
    var body: some View {
        ZStack {
            ARViewContainer(offset: $offset, hidePlane: $hidePlane)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                HStack {
                Button("delay") {
                    usleep(100000)
                }
                    .padding()
                Toggle(isOn: $hidePlane) {
                    Text("Hide plane")
                }
                    .labelsHidden()
                    .padding()
                }
            }
        }
        .onReceive(timer) { _ in
            model.updateValue()
            offset = Float(model.value)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @Binding var offset: Float
    @Binding var hidePlane: Bool
    
    private let objectSize: Float = 0.03
    
    let arView = ARView(frame: .zero)
    let material = SimpleMaterial(color: .gray, roughness: 0.5, isMetallic: true)
    let invisibleMaterial = OcclusionMaterial()
    let keyboardDepth: Float = 0.19
    let keyboardWidth: Float = 0.3
    let screenInset: Float = 0.02
    
    let lightHeight: Float = 0.05
    var lightDepth: Float { -keyboardDepth/2 }
    
    let needDebug = false
    
    func makeUIView(context: Context) -> ARView {
        if needDebug {
            arView.debugOptions = [.showFeaturePoints, .showAnchorOrigins]
        }
        arView.renderOptions = ARView.RenderOptions.disableGroundingShadows
        addEntities(arView)
        return arView
    }
    
    private func addSphere(_ arView: ARView) {
        let sphereAnchor = AnchorEntity(plane: .horizontal)
        let object = MeshResource.generateSphere(radius: objectSize)
        let sphereEntity = ModelEntity(mesh: object, materials: [material])
        sphereAnchor.addChild(sphereEntity)
        arView.scene.anchors.append(sphereAnchor)
        sphereEntity.generateCollisionShapes(recursive: true)
        arView.installGestures([.translation], for: sphereEntity)
    }
    
    private func makeSpheres() -> [Entity] {
        func makeSphere() -> Entity {
            let object = MeshResource.generateSphere(radius: objectSize / 2)
            let sphereEntity = ModelEntity(mesh: object, materials: [material])
            return sphereEntity
        }
        return [makeSphere(), makeSphere(), makeSphere()]
    }
    
    private func makeLight() -> Entity {
        if needDebug {
            let lightObject = MeshResource.generateSphere(radius: objectSize / 4)
            let lightEntity = ModelEntity(mesh: lightObject, materials: [material])
            return lightEntity
        } else {
            let lightObject = PointLight()
            lightObject.light.intensity *= 0.01
            return lightObject
        }
    }
    
    private func addEntities(_ arView: ARView) {
        let anchor = AnchorEntity(plane: .horizontal)
        let object = MeshResource.generatePlane(width: keyboardWidth,
                                                depth: keyboardDepth,
                                                cornerRadius: 0.01)
        let entity = ModelEntity(mesh: object, materials: [material])
        anchor.addChild(entity)
        arView.scene.anchors.append(anchor)
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures([.translation, .rotation], for: entity)
        let lightEntity = makeLight()
        entity.addChild(lightEntity)
        
        let objectsOffsets: Float = 0.05
        for (i, sphere) in makeSpheres().enumerated() {
            let x = (Float(i) * objectsOffsets) - objectsOffsets
            sphere.transform.translation = [x, objectsOffsets, -objectsOffsets]
            entity.addChild(sphere)
        }
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        let screenWidth = keyboardWidth - (screenInset * 2)
        let lightOffset = (offset * screenWidth) - screenWidth/2
        let light = uiView.scene.anchors[0].children[0].children[0]
        light.transform.translation = [lightOffset, lightHeight, lightDepth]
        let plane = uiView.scene.anchors[0].children[0] as! ModelEntity
        if hidePlane {
            plane.model!.materials = [invisibleMaterial]
        } else {
            plane.model!.materials = [material]
        }
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif


import Foundation
import MetalKit

class MetalLinkRenderer : NSObject, MTKViewDelegate, MetalLinkReader {
    let link: MetalLink

    init(link: MetalLink) throws {
        self.link = link
        super.init()
        link.view.delegate = self
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        link.onSizeChange(view, drawableSizeWillChange: size)
    }
    
    func draw(in view: MTKView) {
        guard var sdp = SafeDrawPass.wrap(link)
        else {
            print("Cannot create SafeDrawPass")
            return
        }
        
        twoETutorial.delegatedEncode(in: &sdp)
        
        // Produce drawable from current render state post-encoding
        sdp.renderCommandEncoder.endEncoding()
        guard let drawable = view.currentDrawable
        else { return }
        
        sdp.commandBuffer.present(drawable)
        sdp.commandBuffer.commit()
    }
}

extension MetalLinkRenderer {
    private static var _twoETutorial: TwoETimeRoot?
    var twoETutorial: TwoETimeRoot {
        if let drawing = Self._twoETutorial { return drawing }
        let newDrawing = try! TwoETimeRoot(link: link)
        Self._twoETutorial = newDrawing
        return newDrawing
    }
}

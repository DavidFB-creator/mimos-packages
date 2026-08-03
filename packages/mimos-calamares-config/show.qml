import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 5500
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#FFF8FC"

            Image {
                id: logo
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 80
                width: Math.min(parent.width * 0.55, 520)
                height: 150
                fillMode: Image.PreserveAspectFit
                source: "mimos-logo-horizontal.svg"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: logo.bottom
                anchors.topMargin: 36
                width: parent.width * 0.78
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#30284D"
                font.pixelSize: 28
                font.weight: Font.DemiBold
                text: "Tu ordenador también merece unos mimos"
            }
        }
    }

    Slide {
        centeredText: "Un escritorio acogedor, claro y basado en Arch Linux"
    }

    Slide {
        centeredText: "Estamos preparando tu nuevo hogar digital"
    }

    function onActivate() {
        presentation.currentSlide = 0
    }

    function onLeave() {
    }
}
